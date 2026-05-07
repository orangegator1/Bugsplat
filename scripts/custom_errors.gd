extends Node

func push_error_custom(message: String, levels := 0):
	print("Stack size: ", get_stack().size())
	var stack = get_stack()
	# index 0 is this helper function itself
	# index 1 is the function that called this helper
	# further up the stack can be added as an argument
	var pos = 1 + levels
	if stack.size() > pos:
		var caller = stack[pos]
		var file_path = caller.source
		var line_num = caller.line
		# Format the BBCode URL: [url=res://path.gd:line]path.gd:line[/url]
		var clickable_link = "[url=%s:%d]%s:%d[/url]" % [file_path, line_num, file_path.get_file(), line_num]

		# Use print_rich to render the clickable link in the Output panel
		print_rich("[color='#F66161']ERROR in %s():[/color] %s\n  At: %s" % [caller.function, message, clickable_link])

		# Still push to Debugger tab for a persistent log
		push_error("Error at %s:%d: %s" % [file_path.get_file(), line_num, message])



	else:
		push_error(message)
