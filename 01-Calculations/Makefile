default: build shader

build: obj/main.o obj/MetalAdder.o | bin
	clang++ $^ -framework Foundation -framework Metal -framework CoreGraphics -o bin/main

obj/main.o: src/main.m | obj
	clang++ -c src/main.m -o obj/main.o

obj/MetalAdder.o: src/MetalAdder.m src/MetalAdder.h | obj
	clang++ -c src/MetalAdder.m -o obj/MetalAdder.o

obj:
	mkdir obj
bin:
	mkdir bin

shader:
	xcrun -sdk macosx metal src/add.metal -o bin/add.metallib

clean:
	rm -rf obj bin