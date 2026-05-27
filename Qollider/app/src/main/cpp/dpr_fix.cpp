#include <jni.h>
#include <cstdlib>

// This .so is loaded by System.loadLibrary(), before any Qt code runs.
// Sets QT_ENABLE_HIGHDPI_SCALING=0 so Qt's QHighDpiScaling subsystem
// returns factor=1.0 for every screen at all times, preventing Screen.devicePixelRatio
// from changing when an external display is connected at runtime.
// TODO:: probably a less insane way to do this but I honestly am out of ideas.
__attribute__((constructor))
static void lockDpr() {
    setenv("QT_ENABLE_HIGHDPI_SCALING", "0", 1);
}

// Sets in JNI_OnLoad which fires just after the constructor.
extern "C" JNIEXPORT jint JNI_OnLoad(JavaVM*, void*) {
    setenv("QT_ENABLE_HIGHDPI_SCALING", "0", 1);
    return JNI_VERSION_1_6;
}
