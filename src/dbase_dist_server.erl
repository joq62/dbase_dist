%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : resource discovery accroding to OPT in Action 
%%% This service discovery is adapted to 
%%% Type = application 
%%% Instance ={ip_addr,{IP_addr,Port}}|{erlang_node,{ErlNode}}
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(dbase_dist_server).

-behaviour(gen_server). 

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
% -include("").
%% --------------------------------------------------------------------
%% External exports
-export([]).

%% gen_server callbacks

-export([start/0,stop/0]).

-export([init/1, handle_call/3,handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).

%% ====================================================================
%% External functions
%% ====================================================================
start()-> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).
stop()-> gen_server:call(?MODULE, {stop},infinity).




%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
    DbaseNodes=connect_nodes(),
    start_dbase(DbaseNodes),
  %  IsLeader=start_bully_election(),
  %  case IsLeader of
%	false->
	 %   start_as_slave(DbaseNodes);
%	true->
%	    start_as_leader(DbaseNodes)
 %   end,
    {ok, #state{}}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_call({stop}, _From, State) ->
    {stop, normal, shutdown_ok, State};

handle_call(Request, From, State) ->
    Reply = {unmatched_signal,?MODULE,Request,From},
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------


handle_cast(Msg, State) ->
    io:format("unmatched match cast ~p~n",[{Msg,?MODULE,?LINE,time()}]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Exported functions
%% --------------------------------------------------------------------


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

connect_nodes()->
    AppFile=atom_to_list(dbase_dist)++".app",
    Env=appfile:read(AppFile,env),
    {nodes,DbaseNodes}=lists:keyfind(nodes,1,Env),
    RunningNodes= [Node||Node<-DbaseNodes,
			 pong=:=net_adm:ping(Node),
			 Node/=node(),
			 yes=:=rpc:call(Node,mnesia,system_info,[is_running],1000)
	  ],
    
    RunningNodes.


start_dbase(stop)->
    ok=io:format("stop ~p~n",[{?FUNCTION_NAME,?MODULE,?LINE}]),
    ok;
start_dbase([])->
    mnesia:stop(),
    mnesia:delete_schema([node()]),
    mnesia:start(),
    %% First to start
    ok=db_lock:create_table(),
    {atomic,ok}=db_lock:create(lock1,0,node1),
    ok=io:format("[] ~p~n",[{node(),?FUNCTION_NAME,?MODULE,?LINE}]),
    ok;

start_dbase([Node|T])->
    ok=io:format("Node and node()~p~n",[{Node,node(),?FUNCTION_NAME,?MODULE,?LINE}]),
    mnesia:stop(),
    mnesia:delete_schema([node()]),
    mnesia:start(),
    MyNode=node(),
    NewT=case rpc:call(Node,db_lock,add_node,[MyNode,MyNode,ram_copies],1000) of
	     ok->
		 stop;
	     Error ->
		 io:format("Error~p~n",[{Error,Node,node(),?FUNCTION_NAME,?MODULE,?LINE}]),
		   T
	   end,
    start_dbase(NewT).

    
start_bully_election()->
    application:stop(bully),
    application:start(bully),
    timer:sleep(5000),
    bully:am_i_leader(node()).

start_as_slave(DbaseNodes)->
  %  mnesia:stop(),
  %  mnesia:delete_schema([node()]),
  %  mnesia:start(),
  %  start_as_leader(DbaseNodes),
    ok.
    
start_as_leader([])-> %First leader
%    mnesia:stop(),
%    mnesia:delete_schema([node()]),
%    mnesia:start(),
    
    ok;

start_as_leader(DbaseNodes)->
 %   mnesia:stop(),
 %   mnesia:delete_schema([node()]),
 %   mnesia:start(),
    
  %  [add_node(Node,ram_copies)||Node<-DbaseNodes].
    ok.
    

add_node(Node,StorageType)->
    Result=case mnesia:change_config(extra_db_nodes, [Node]) of
	       {ok,[Node]}->
		   mnesia:add_table_copy(schema, node(),StorageType),
		   Tables=mnesia:system_info(tables),
		   mnesia:wait_for_tables(Tables,20*1000);
	       Reason ->
		   Reason
	   end,
    Result.
