/*
 * Vendored JNI platform header for Windows.
 * Extracted from OpenJDK — compatible with all JDK versions.
 */

#ifndef _JAVASOFT_JNI_MD_H_
#define _JAVASOFT_JNI_MD_H_

#define JNIEXPORT __declspec(dllexport)
#define JNIIMPORT __declspec(dllimport)
#define JNICALL __stdcall

typedef int jint;
typedef __int64 jlong;
typedef signed char jbyte;

#endif /* _JAVASOFT_JNI_MD_H_ */
