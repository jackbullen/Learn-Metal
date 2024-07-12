SRCS := $(wildcard src/*.cpp)
OBJS := $(patsubst src/%.cpp, obj/%.o, $(SRCS))
EXES := $(patsubst src/%.cpp, bin/%, $(SRCS))

CC := clang++
CFLAGS := -Wall -std=c++17 -I../../metal-cpp -I../../metal-cpp-extensions -fno-objc-arc
LDFLAGS := -framework Metal -framework Foundation -framework Cocoa -framework CoreGraphics -framework MetalKit

ifdef DEBUG
    CFLAGS += -g
else
    CFLAGS += -O2
endif

ifdef ASAN
    CFLAGS += -fsanitize=address
endif

all: $(OBJS) $(EXES)

bin/%: obj/%.o | bin
	$(CC) $(LDFLAGS) $< -o $@

obj/%.o: src/%.cpp | obj
	$(CC) $(CFLAGS) -c $< -o $@

obj:
	mkdir -p obj
bin:
	mkdir -p bin

clean:
	rm -rf obj bin