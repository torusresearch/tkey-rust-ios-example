#include <stdbool.h>
#include <stdint.h>

#ifndef __TKEY_H__
#define __TKEY_H__ // Include guard

    #ifdef __cplusplus // Required for C++ compiler
    extern "C" {
    #endif

        //Forward Declarations
        struct ShareStore;
        struct FFIStorageLayer;
        struct TKey;
        struct TKeyReconstruction;
        struct ServiceProvider;
        struct Metadata;
        struct ShareStorePolyIDShareIndexMap;
        struct LocalMetadataTransitions;

        //Methods
        void string_destroy(char *ptr);
        struct ShareStore* json_to_share_store(char* json, int* error_code);
        void share_store_free(struct ShareStore* ptr);
        struct FFIStorageLayer* storage_layer(bool enable_logging, char* host_url, unsigned long int server_time_offset, char* (*network_callback)(char*, char*, int*), int* error_code);
        void storage_layer_free(struct FFIStorageLayer* ptr);
        struct ServiceProvider* service_provider(bool enable_logging, char *postbox_key, char *curve_n, int *error_code);
        void service_provider_free(struct ServiceProvider* prt);
        struct FFIThresholdKey* threshold_key(char* private_key, struct Metadata* metadata, struct ShareStorePolyIDShareIndexMap* shares, struct FFIStorageLayer* storage_layer, struct ServiceProvider* service_provider, struct LocalMetadataTransitions* local_metadata_transitions, struct Metadata* last_fetch_cloud_metadata, bool enable_logging, bool manual_sync, int* error_code);
        struct TKey* threshold_key_initialize(struct FFIThresholdKey* threshold_key, char* import_share, struct ShareStore* input, bool never_initialize_new_key, struct ServiceProvider* service_provider, bool include_local_metadata_transitions, char* curve_n, int* error_code);
        struct TKeyReconstruction* threshold_key_reconstruct(struct FFIThresholdKey* threshold_key, char* curve_n, int* error_code);
        void threshold_key_free(struct FFIThresholdKey* ptr);
        void tkey_reconstruction_free(struct TKeyReconstruction* ptr);
        void tkey_free(struct TKey* ptr);

    #ifdef __cplusplus
    } // extern "C"
    #endif
#endif // __TKEY_H__
