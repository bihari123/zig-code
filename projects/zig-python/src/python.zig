const c = @cImport({
    @cInclude("Python.h");
});

pub const PythonError = error{
    InitializationFailed,
    ImportFailed,
    FunctionCallFailed,
    InvalidResult,
};

pub const Python = struct {
    const Self = @This();

    pub fn init() PythonError!void {
        if (c.Py_IsInitialized() == 0) {
            if (c.Py_Initialize() != 0) {
                return PythonError.InitializationFailed;
            }
        }
    }

    pub fn deinit() void {
        c.Py_Finalize();
    }

    pub fn analyzeEmotion(text: []const u8) PythonError![]const u8 {
        const module = c.PyImport_ImportModule("emotional_analysis") orelse
            return PythonError.ImportFailed;
        defer c.Py_DECREF(module);

        const func = c.PyObject_GetAttrString(module, "analyze_emotion") orelse
            return PythonError.ImportFailed;
        defer c.Py_DECREF(func);

        const args = c.PyTuple_New(1);
        const py_text = c.PyUnicode_FromStringAndSize(text.ptr, text.len);
        _ = c.PyTuple_SetItem(args, 0, py_text);

        const result = c.PyObject_CallObject(func, args) orelse
            return PythonError.FunctionCallFailed;
        defer c.Py_DECREF(result);

        return c.PyUnicode_AsUTF8(result) orelse
            return PythonError.InvalidResult;
    }
};
