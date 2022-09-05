#ifndef __TKEY_H__
#define __TKEY_H__ // Include guard

    #ifdef __cplusplus // Required for C++ compiler
    extern "C" {
    #endif
        const char* sha256_hash(const char* input);
        void string_destroy(char *ptr);
    #ifdef __cplusplus
    } // extern "C"
    #endif
#endif // __TKEY_H__