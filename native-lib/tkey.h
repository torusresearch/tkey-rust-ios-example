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
        struct KeyReconstructionDetails;
        struct ServiceProvider;
        struct Metadata;
        struct ShareStorePolyIDShareIndexMap;
        struct LocalMetadataTransitions;
        struct KeyDetails;
        struct KeyPoint;

        //Methods
        void string_destroy(char *ptr);
        char* generate_private_key( char* curve_n, int* error_code);
        char* point_get_x(struct KeyPoint* point, int* error_code);
        char* point_get_y(struct KeyPointPoint* point, int* error_code);
        void point_free(struct KeyPointPoint* point);
        char* key_reconstruction_get_private_key(struct KeyReconstructionDetails* key_details, int* error_code);
        int key_reconstruction_get_seed_phrase_len(struct KeyReconstructionDetails* key_details, int* error_code);
        char* key_reconstruction_get_seed_phrase_at(struct KeyReconstructionDetails* key_details, int at, int* error_code);
        int key_reconstruction_get_all_keys_len(struct KeyReconstructionDetails* key_details, int* error_code);
        char* key_reconstruction_get_all_keys_at(struct KeyReconstructionDetails* key_details, int at, int* error_code);
        void key_reconstruction_details_free(struct KeyReconstructionDetails* key_details);
        struct KeyPointPoint* key_details_get_pub_key_point(struct KeyDetails* key_details, int* error_code);
        int key_details_get_required_shares(struct KeyDetails* key_details, int* error_code);
        unsigned int key_details_get_threshold(struct KeyDetails* key_details, int* error_code);
        unsigned int key_details_get_total_shares(struct KeyDetails* key_details, int* error_code);
        char* key_details_get_share_descriptions(struct KeyDetails* key_details, int* error_code);
        void key_details_free(struct KeyDetails* key_details);
        struct ShareStore* json_to_share_store(char* json, int* error_code);
        void share_store_free(struct ShareStore* ptr);
        struct FFIStorageLayer* storage_layer(bool enable_logging, char* host_url, unsigned long int server_time_offset, char* (*network_callback)(char*, char*, int*), int* error_code);
        void storage_layer_free(struct FFIStorageLayer* ptr);
        struct ServiceProvider* service_provider(bool enable_logging, char* postbox_key, char* curve_n, int* error_code);
        void service_provider_free(struct ServiceProvider* prt);
        struct FFIThresholdKey* threshold_key(char* private_key, struct Metadata* metadata, struct ShareStorePolyIDShareIndexMap* shares, struct FFIStorageLayer* storage_layer, struct ServiceProvider* service_provider, struct LocalMetadataTransitions* local_metadata_transitions, struct Metadata* last_fetch_cloud_metadata, bool enable_logging, bool manual_sync, int* error_code);
        struct KeyDetails* threshold_key_initialize(struct FFIThresholdKey* threshold_key, char* import_share, struct ShareStore* input, bool never_initialize_new_key, struct ServiceProvider* service_provider, bool include_local_metadata_transitions, char* curve_n, int* error_code);
        struct KeyReconstructionDetails* threshold_key_reconstruct(struct FFIThresholdKey* threshold_key, char* curve_n, int* error_code);
        void threshold_key_free(struct FFIThresholdKey* ptr);

    #ifdef __cplusplus
    } // extern "C"
    #endif
#endif // __TKEY_H__