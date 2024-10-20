# Tom Cat Voice Effect: Real-Time Audio DSP in Zig

This project implements a real-time audio effect that transforms voice input to sound like Tom Cat from Tom and Jerry cartoons. It demonstrates the application of digital signal processing (DSP) techniques in Zig, while interfacing with the C-based PortAudio library.

## Technical Overview

### Digital Signal Processing Techniques

1. **Pitch Shifting**
   - Implemented using a time-domain resampling technique.
   - Utilizes linear interpolation for smooth pitch transitions.
   - Formula: `output[i] = input[phase]*(1-frac) + input[phase+1]*frac`
   where `phase` is incremented by `PITCH_SHIFT_FACTOR` each sample.

2. **Resonant Filtering**
   - Applies a second-order IIR (Infinite Impulse Response) filter.
   - Enhances specific frequencies to emulate cat vocalization.
   - Transfer function: `H(z) = (b0 + b1*z^-1 + b2*z^-2) / (1 + a1*z^-1 + a2*z^-2)`

3. **Nonlinear Distortion**
   - Uses hyperbolic tangent function for soft clipping.
   - Adds harmonic content to simulate vocal tract nonlinearities.
   - Formula: `output = tanh(input * DISTORTION_FACTOR) * 0.5`

### Zig and C Interoperability

This project showcases Zig's ability to interface with C libraries, specifically PortAudio for real-time audio I/O.

1. **C Library Integration**
   - Utilizes `@cImport` to include C headers:
     ```zig
     const c = @cImport({
         @cInclude("portaudio.h");
         @cInclude("math.h");
     });
     ```
   - Demonstrates calling C functions from Zig code.

2. **Callback Function Implementation**
   - Implements PortAudio callbacks in Zig, adhering to C calling conventions:
     ```zig
     fn recordCallback(
         input: ?*const anyopaque,
         output: ?*anyopaque,
         frameCount: c_ulong,
         timeInfo: [*c]const c.PaStreamCallbackTimeInfo,
         statusFlags: c.PaStreamCallbackFlags,
         userData: ?*anyopaque,
     ) callconv(.C) c_int {
         // Implementation
     }
     ```

3. **Memory Management**
   - Utilizes Zig's allocator for safe memory management in a C context.

4. **Type Casting**
   - Demonstrates safe casting between Zig and C types:
     ```zig
     const data: *PaTestData = @ptrCast(@alignCast(userData.?));
     ```

## Build System

The project uses Zig's build system to manage compilation and linking:

```zig
exe.linkSystemLibrary("portaudio");
exe.linkLibC();
exe.addIncludePath(.{ .cwd_relative = "/usr/include" });
```

This setup allows seamless integration of the C library with Zig code.

## Challenges and Solutions

1. **Real-Time Processing**: Implemented efficient algorithms to ensure low-latency processing.
2. **C Interoperability**: Carefully managed type conversions and memory to safely interface with C code.
3. **Audio Buffer Management**: Implemented circular buffer techniques for continuous audio processing.

## Future Enhancements

- Implement more advanced DSP techniques like formant shifting.
- Explore SIMD optimizations for improved performance.
- Implement a plugin version (VST/AU) for use in digital audio workstations.

## Building and Running

Ensure you have Zig and PortAudio installed, then:

```bash
zig build
zig build run
```

## Dependencies

- Zig (latest version)
- PortAudio v19+

## Contributing

Contributions to improve DSP algorithms, optimize performance, or enhance C interoperability are welcome. Please submit a pull request or open an issue for discussion.

## License

[MIT License](LICENSE)
