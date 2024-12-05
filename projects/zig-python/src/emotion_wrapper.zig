// emotion_wrapper.zig
const std = @import("std");
const py = @cImport({
    @cInclude("Python.h");
});

pub const EmotionAnalyzer = struct {
    py_module: *py.PyObject,
    analyzer_class: *py.PyObject,
    analyzer_instance: *py.PyObject,

    pub fn init() !EmotionAnalyzer {
        if (py.Py_IsInitialized() == 0) {
            py.Py_Initialize();
        }

        // Add current directory to Python path
        const sys = py.PyImport_ImportModule("sys") orelse return error.PythonImportError;
        defer py.Py_DecRef(sys);

        const path = py.PyObject_GetAttrString(sys, "path") orelse return error.PythonAttributeError;
        defer py.Py_DecRef(path);

        _ = py.PyList_Append(path, py.PyUnicode_FromString("."));

        // Import our Python module
        const module = py.PyImport_ImportModule("emotion_analyzer") orelse return error.PythonImportError;
        const class = py.PyObject_GetAttrString(module, "SubtitleEmotionAnalyzer") orelse return error.PythonAttributeError;
        const instance = py.PyObject_CallObject(class, null) orelse return error.PythonCallError;

        return EmotionAnalyzer{
            .py_module = module,
            .analyzer_class = class,
            .analyzer_instance = instance,
        };
    }

    pub fn deinit(self: *EmotionAnalyzer) void {
        py.Py_DecRef(self.analyzer_instance);
        py.Py_DecRef(self.analyzer_class);
        py.Py_DecRef(self.py_module);
        py.Py_Finalize();
    }

    pub fn analyzeFile(self: *EmotionAnalyzer, input_file: []const u8, output_file: []const u8) !void {
        const args = py.PyTuple_New(2);
        defer py.Py_DecRef(args);

        _ = py.PyTuple_SetItem(args, 0, py.PyUnicode_FromString(input_file.ptr));
        _ = py.PyTuple_SetItem(args, 1, py.PyUnicode_FromString(output_file.ptr));

        const result = py.PyObject_CallMethod(
            self.analyzer_instance,
            "analyze_emotions_in_chunks",
            "ss",
            input_file.ptr,
            output_file.ptr,
        );

        if (result == null) {
            py.PyErr_Print();
            return error.PythonCallFailed;
        }
        defer py.Py_DecRef(result);
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 3) {
        std.debug.print("Usage: {s} <input_srt> <output_json>\n", .{args[0]});
        return;
    }

    var analyzer = try EmotionAnalyzer.init();
    defer analyzer.deinit();

    try analyzer.analyzeFile(args[1], args[2]);
}
