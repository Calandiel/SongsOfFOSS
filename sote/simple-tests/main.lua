return function ()
	--require "sote.simple-tests.queue"

	require "sote.codegen.output.generated".test_save_load_0()
	require "sote.codegen.output.generated".test_save_load_1()
	require "sote.codegen.output.generated".test_save_load_2()

	require "sote.codegen.output.generated".test_set_get_0()
	require "sote.codegen.output.generated".test_set_get_1()
	require "sote.codegen.output.generated".test_set_get_2()
end