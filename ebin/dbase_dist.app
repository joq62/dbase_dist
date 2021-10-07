%% This is the application resource file (.app file) for the 'base'
%% application.
{application, dbase_dist,
[{description, "Mnesia based distributed dbase" },
{vsn, "0.1.0" },
{modules, 
	  [dbase_dist,dbase_dist_sup,dbase_dist_server]},
{registered,[dbase_dist]},
{applications, [kernel,stdlib]},
{mod, {dbase_dist,[]}},
{start_phases, []},
{git_path,"https://github.com/joq62/dbase_dist.git"},
{env,[]}
]}.
