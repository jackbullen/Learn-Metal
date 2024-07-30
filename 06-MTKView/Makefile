CC := clang++
CFLAGS := -Wall -I../metal-cpp -I../metal-cpp-extensions -fno-objc-arc
LDFLAGS := -framework Metal -framework MetalKit -framework AppKit -framework CoreGraphics

SRCS := $(wildcard src/*.m)
OBJS := $(patsubst src/%.m,obj/%.o,$(SRCS))

bin/main: $(OBJS) | bin
	$(CC) $(LDFLAGS) $^ -o $@

obj/%.o: src/%.m | obj
	$(CC) $(CFLAGS) -c $< -o $@

bin:
	mkdir bin
obj:
	mkdir obj

clean:
	rm -r obj bin
