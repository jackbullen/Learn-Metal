CC := clang++
CFLAGS := -Wall -std=c++17 -I./metal-cpp -I./metal-cpp-extensions -fno-objc-arc
LDFLAGS := -framework Metal -framework MetalKit -framework CoreGraphics -framework Cocoa

SRCS := $(wildcard src/*.cpp src/*.mm)
OBJS := $(patsubst src/%.cpp,obj/%.o,$(patsubst src/%.mm,obj/%.o,$(SRCS)))

bin/main: $(OBJS) | bin
	$(CC) $(LDFLAGS) $^ -o $@

obj/%.o: src/%.cpp | obj
	$(CC) $(CFLAGS) -c $< -o $@

obj/%.o: src/%.mm | obj
	$(CC) $(CFLAGS) -c $< -o $@

bin:
	mkdir bin
obj:
	mkdir obj

clean:
	rm -r obj bin
