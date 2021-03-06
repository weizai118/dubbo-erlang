%%------------------------------------------------------------------------------
%% Licensed to the Apache Software Foundation (ASF) under one or more
%% contributor license agreements.  See the NOTICE file distributed with
%% this work for additional information regarding copyright ownership.
%% The ASF licenses this file to You under the Apache License, Version 2.0
%% (the "License"); you may not use this file except in compliance with
%% the License.  You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%------------------------------------------------------------------------------
-module(dubboerl).

-include("dubboerl.hrl").
-include("dubbo.hrl").

%% API
-export([init/0, start_consumer/0, start_provider/0]).

init() ->
    ok = start_consumer(),
    ok = start_provider(),
    ok.


start_consumer() ->
    ConsumerList = application:get_env(dubboerl, consumer, []),
    ApplicationName = application:get_env(dubboerl, application, <<"defaultApplication">>),
    lists:map(fun({Interface, Option}) ->
        ConsumerInfo = dubbo_config_util:gen_consumer(ApplicationName, Interface, Option),
        dubbo_zookeeper:register_consumer(ConsumerInfo),
        logger:info("register consumer success ~p", [Interface])
              end, ConsumerList),
    ok.

start_provider() ->
    ProviderList = application:get_env(dubboerl, provider, []),
    ApplicationName = application:get_env(dubboerl, application, <<"defaultApplication">>),
    DubboServerPort = application:get_env(dubboerl, port, ?DUBBO_DEFAULT_PORT),
    start_provider_listen(DubboServerPort),
    lists:map(fun({ImplModuleName, BehaviourModuleName, Interface, Option}) ->
        ok = dubbo_provider_protocol:register_impl_provider(Interface, ImplModuleName, BehaviourModuleName),
        MethodList = apply(BehaviourModuleName, get_method_999_list, []),
        ProviderInfo = dubbo_config_util:gen_provider(ApplicationName, DubboServerPort, Interface, MethodList, Option),
        dubbo_zookeeper:register_provider(ProviderInfo),
        logger:info("register provider success ~p ~p", [ImplModuleName, Interface])
              end, ProviderList),
    ok.

start_provider_listen(Port) ->
    {ok, _} = ranch:start_listener(tcp_reverse,
        ranch_tcp, [{port, Port}], dubbo_provider_protocol, []),
    ok.




