# SRCS := $(wildcard *.m)
# OBJS := $(patsubst %.m, obj/%.o, $(SRCS))
# EXES := $(patsubst %.m, bin/%, $(SRCS))

CC := clang++
CFLAGS := -Wall -fno-objc-arc
LDFLAGS := -framework Metal -framework MetalKit -framework CoreGraphics -framework Cocoa

all: AppDelegate.o AppAdapter.o ViewController.o Renderer.o main

main: main.o AppDelegate.o AppAdapter.o ViewController.o Renderer.o
	$(CC) $(LDFLAGS) $^ -o $@

main.o: main.m
	$(CC) $(CFLAGS) -c $< -o $@

AppDelegate.o: AppDelegate.m
	$(CC) $(CFLAGS) -c $< -o $@

AppAdapter.o: AppAdapter.mm
	$(CC) -std=c++17 -I./metal-cpp -I./metal-cpp-extensions $(CFLAGS) -c $< -o $@

ViewController.o: ViewController.mm
	$(CC) -std=c++17 -I./metal-cpp -I./metal-cpp-extensions $(CFLAGS) -c $< -o $@

Renderer.o: Renderer.cpp
	$(CC) -std=c++17 -I./metal-cpp -I./metal-cpp-extensions $(CFLAGS) -c $< -o $@

clean:
	rm *.o main