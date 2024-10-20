// tom_cat_effect.zig

const std = @import("std");
const c = @cImport({
    @cInclude("portaudio.h");
    @cInclude("math.h");
});

const SAMPLE_RATE: f32 = 44100;
const FRAMES_PER_BUFFER: u32 = 512;
const NUM_SECONDS: u32 = 5;
const NUM_CHANNELS: u32 = 1;

const PITCH_SHIFT_FACTOR: f32 = 1.5;
const MEOW_FREQ: f32 = 500.0;
const MEOW_BANDWIDTH: f32 = 100.0;
const DISTORTION_FACTOR: f32 = 1.2;

const PaTestData = struct {
    recordedSamples: []f32,
    frameIndex: usize,
    maxFrameIndex: usize,
};
fn recordCallback(
    input: ?*const anyopaque,
    _: ?*anyopaque,
    frameCount: c_ulong,
    _: [*c]const c.PaStreamCallbackTimeInfo,
    _: c.PaStreamCallbackFlags,
    userData: ?*anyopaque,
) callconv(.C) c_int {
    const data: *PaTestData = @ptrCast(@alignCast(userData.?));
    const inputBuffer: [*]const f32 = @ptrCast(@alignCast(input.?));
    var framesToCalc = frameCount;

    if (data.frameIndex + framesToCalc > data.maxFrameIndex) {
        framesToCalc = data.maxFrameIndex - data.frameIndex;
    }

    var i: usize = 0;
    while (i < framesToCalc) : (i += 1) {
        data.recordedSamples[data.frameIndex + i] = inputBuffer[i];
    }
    data.frameIndex += framesToCalc;

    return 0; // paContinue
}

fn playCallback(
    _: ?*const anyopaque,
    output: ?*anyopaque,
    frameCount: c_ulong,
    _: [*c]const c.PaStreamCallbackTimeInfo,
    _: c.PaStreamCallbackFlags,
    userData: ?*anyopaque,
) callconv(.C) c_int {
    const data: *PaTestData = @ptrCast(@alignCast(userData.?));
    const outputBuffer: [*]f32 = @ptrCast(@alignCast(output.?));

    var i: usize = 0;
    while (i < frameCount) : (i += 1) {
        if (data.frameIndex < data.maxFrameIndex) {
            outputBuffer[i] = data.recordedSamples[data.frameIndex];
            data.frameIndex += 1;
        } else {
            outputBuffer[i] = 0;
        }
    }

    return 0; // paContinue
}

fn applyTomCatEffect(buffer: []f32) void {
    const tempBuffer = buffer;

    var phase: f32 = 0;
    const phaseIncrement = PITCH_SHIFT_FACTOR;

    var b0: f32 = 0;
    var b1: f32 = 0;
    var b2: f32 = 0;
    var a0: f32 = 0;
    var a1: f32 = 0;
    var a2: f32 = 0;

    const w0 = 2.0 * std.math.pi * MEOW_FREQ / SAMPLE_RATE;
    const alpha = @sin(w0) * std.math.sinh(@log(2.0) / 2.0 * MEOW_BANDWIDTH * w0 / @sin(w0));

    a0 = 1.0 + alpha;
    b0 = alpha / a0;
    b1 = 0;
    b2 = -alpha / a0;
    a1 = -2.0 * @cos(w0) / a0;
    a2 = (1.0 - alpha) / a0;

    var x1: f32 = 0;
    var x2: f32 = 0;
    var y1: f32 = 0;
    var y2: f32 = 0;

    for (buffer) |*sample| {
        const readIndex = @as(usize, @intFromFloat(@floor(phase)));
        const frac = phase - @floor(phase);
        const interpolatedSample = if (readIndex < tempBuffer.len - 1)
            tempBuffer[readIndex] * (1.0 - frac) + tempBuffer[readIndex + 1] * frac
        else
            tempBuffer[readIndex];

        phase += phaseIncrement;
        if (phase >= @as(f32, @floatFromInt(tempBuffer.len))) {
            phase -= @as(f32, @floatFromInt(tempBuffer.len));
        }

        const x0 = interpolatedSample;
        const y0 = b0 * x0 + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;
        x2 = x1;
        x1 = x0;
        y2 = y1;
        y1 = y0;

        sample.* = std.math.tanh(y0 * DISTORTION_FACTOR) * 0.5;
    }
}

pub fn main() !void {
    var stream: ?*c.PaStream = null;
    var err: c.PaError = undefined;

    const totalFrames = NUM_SECONDS * SAMPLE_RATE;
    const numSamples = totalFrames * NUM_CHANNELS;

    var data = PaTestData{
        .recordedSamples = try std.heap.page_allocator.alloc(f32, @as(usize, @intFromFloat(numSamples))),
        .frameIndex = 0,
        .maxFrameIndex = @as(usize, @intFromFloat(totalFrames)),
    };
    defer std.heap.page_allocator.free(data.recordedSamples);

    err = c.Pa_Initialize();
    if (err != c.paNoError) {
        std.debug.print("PortAudio error: {s}\n", .{c.Pa_GetErrorText(err)});
        return error.PortAudioInitFailed;
    }
    defer _ = c.Pa_Terminate();

    // Record
    err = c.Pa_OpenDefaultStream(
        &stream,
        NUM_CHANNELS,
        0,
        c.paFloat32,
        SAMPLE_RATE,
        FRAMES_PER_BUFFER,
        recordCallback,
        &data,
    );
    if (err != c.paNoError) {
        std.debug.print("PortAudio error: {s}\n", .{c.Pa_GetErrorText(err)});
        return error.PortAudioOpenStreamFailed;
    }

    err = c.Pa_StartStream(stream);
    if (err != c.paNoError) {
        std.debug.print("PortAudio error: {s}\n", .{c.Pa_GetErrorText(err)});
        return error.PortAudioStartStreamFailed;
    }

    std.debug.print("Recording for {} seconds...\n", .{NUM_SECONDS});
    c.Pa_Sleep(NUM_SECONDS * 1000);

    err = c.Pa_StopStream(stream);
    if (err != c.paNoError) {
        std.debug.print("PortAudio error: {s}\n", .{c.Pa_GetErrorText(err)});
        return error.PortAudioStopStreamFailed;
    }

    err = c.Pa_CloseStream(stream);
    if (err != c.paNoError) {
        std.debug.print("PortAudio error: {s}\n", .{c.Pa_GetErrorText(err)});
        return error.PortAudioCloseStreamFailed;
    }

    std.debug.print("Applying Tom Cat effect...\n", .{});
    applyTomCatEffect(data.recordedSamples);

    // Playback
    data.frameIndex = 0;

    err = c.Pa_OpenDefaultStream(
        &stream,
        0,
        NUM_CHANNELS,
        c.paFloat32,
        SAMPLE_RATE,
        FRAMES_PER_BUFFER,
        playCallback,
        &data,
    );
    if (err != c.paNoError) {
        std.debug.print("PortAudio error: {s}\n", .{c.Pa_GetErrorText(err)});
        return error.PortAudioOpenStreamFailed;
    }

    std.debug.print("Starting playback...\n", .{});
    err = c.Pa_StartStream(stream);
    if (err != c.paNoError) {
        std.debug.print("PortAudio error: {s}\n", .{c.Pa_GetErrorText(err)});
        return error.PortAudioStartStreamFailed;
    }

    while (data.frameIndex < data.maxFrameIndex) {
        c.Pa_Sleep(100);
    }

    err = c.Pa_StopStream(stream);
    if (err != c.paNoError) {
        std.debug.print("PortAudio error: {s}\n", .{c.Pa_GetErrorText(err)});
        return error.PortAudioStopStreamFailed;
    }

    err = c.Pa_CloseStream(stream);
    if (err != c.paNoError) {
        std.debug.print("PortAudio error: {s}\n", .{c.Pa_GetErrorText(err)});
        return error.PortAudioCloseStreamFailed;
    }

    std.debug.print("Playback finished.\n", .{});
}
