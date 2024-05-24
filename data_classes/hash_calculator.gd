extends Node


const CHUNK_SIZE = 1024

func hash_file(path):
	var ctx = HashingContext.new()
	var file = File.new()
	# Start a SHA-256 context.
	ctx.start(HashingContext.HASH_SHA256)
	if not file.file_exists(path):
		return
	
	file.open(path, File.READ)
	# Update the context after reading each chunk.
	while not file.eof_reached():
		ctx.update(file.get_buffer(CHUNK_SIZE))
	
	# Get the computed hash.
	var res = ctx.finish()
	# Convert the hash to hexadecimal number in String
	return res.hex_encode()
