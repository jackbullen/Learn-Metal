default: build shader

build: src/main.o src/MetalAdder.o
	clang++ $^ -framework Foundation -framework Metal -framework CoreGraphics -o main

src/main.o: src/main.m
	clang++ -c src/main.m -o src/main.o

src/MetalAdder.o: src/MetalAdder.m src/MetalAdder.h
	clang++ -c src/MetalAdder.m -o src/MetalAdder.o

shader:
	xcrun -sdk macosx metal src/add.metal -o src/add.metallib

clean:
	rm main src/main.o src/MetalAdder.o src/add.metallib