# Cpp Adapter

Connect Objective C application codes with Cpp Metal rendering codes.

# Todo: 

- Change .m files. Only AppAdapter.mm?
- clangd find metal-cpp and extensions

# Source

- Used as a starting point. However, there are a few differences. No storyboard or Xcode build, app delegate functions, cpp Renderer is only initialized with MTLDevice and its draw method takes MTKView as input.
    - https://github.com/DataDrivenEngineer/metal-videos
    - https://www.youtube.com/watch?v=oMdt5zWXUto
