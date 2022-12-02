#include <stdbool.h>
#include <stdint.h>

#ifndef __TKEY_H__
#define __TKEY_H__ // Include guard

    #ifdef __cplusplus // Required for C++ compiler
    extern "C" {
    #endif

        //Forward Declarations
        struct ShareStore;
        struct ShareStoreMap;
        struct FFIStorageLayer;
        struct KeyReconstructionDetails;
        struct ServiceProvider;
        struct Metadata;
        struct ShareStorePolyIDShareIndexMap;
        struct LocalMetadataTransitions;
        struct KeyDetails;
        struct KeyPoint;
        struct ShareTransferStore;
        struct GenerateShareStoreResult;

        //Methods
        char* get_version(int* error_code);
        void string_destroy(char *ptr);
        char* generate_private_key( char* curve_n, int* error_code);
        char* point_get_x(struct KeyPoint* point, int* error_code);
        char* point_get_y(struct KeyPoint* point, int* error_code);
        void point_free(struct KeyPoint* point);
        char* key_reconstruction_get_private_key(struct KeyReconstructionDetails* key_details, int* error_code);
        int key_reconstruction_get_seed_phrase_len(struct KeyReconstructionDetails* key_details, int* error_code);
        char* key_reconstruction_get_seed_phrase_at(struct KeyReconstructionDetails* key_details, int at, int* error_code);
        int key_reconstruction_get_all_keys_len(struct KeyReconstructionDetails* key_details, int* error_code);
        char* key_reconstruction_get_all_keys_at(struct KeyReconstructionDetails* key_details, int at, int* error_code);
        void key_reconstruction_details_free(struct KeyReconstructionDetails* key_details);
        struct KeyPoint* key_details_get_pub_key_point(struct KeyDetails* key_details, int* error_code);
        int key_details_get_required_shares(struct KeyDetails* key_details, int* error_code);
        unsigned int key_details_get_threshold(struct KeyDetails* key_details, int* error_code);
        unsigned int key_details_get_total_shares(struct KeyDetails* key_details, int* error_code);
        char* key_details_get_share_descriptions(struct KeyDetails* key_details, int* error_code);
        void key_details_free(struct KeyDetails* key_details);
        struct ShareStore* json_to_share_store(char* json, int* error_code);
        void share_store_free(struct ShareStore* ptr);
        struct FFIStorageLayer* storage_layer(bool enable_logging, char* host_url, long long int server_time_offset, char* (*network_callback)(char*, char*, int*), int* error_code);
        void storage_layer_free(struct FFIStorageLayer* ptr);
        struct ServiceProvider* service_provider(bool enable_logging, char* postbox_key, char* curve_n, int* error_code);
        void service_provider_free(struct ServiceProvider* prt);
        struct FFIThresholdKey* threshold_key(char* private_key, struct Metadata* metadata, struct ShareStorePolyIDShareIndexMap* shares, struct FFIStorageLayer* storage_layer, struct ServiceProvider* service_provider, struct LocalMetadataTransitions* local_metadata_transitions, struct Metadata* last_fetch_cloud_metadata, bool enable_logging, bool manual_sync, int* error_code);
        struct KeyDetails* threshold_key_initialize(struct FFIThresholdKey* threshold_key, char* import_share, struct ShareStore* input, bool never_initialize_new_key, bool include_local_metadata_transitions, char* curve_n, int* error_code);
        struct KeyDetails* threshold_key_get_key_details(struct FFIThresholdKey* threshold_key, int* error_code);
        struct KeyReconstructionDetails* threshold_key_reconstruct(struct FFIThresholdKey* threshold_key, char* curve_n, int* error_code);
        void threshold_key_free(struct FFIThresholdKey* ptr);
        void share_store_map_free(struct ShareStoreMap* ptr);
        char* generate_new_share_store_result_get_shares_index(struct GenerateShareStoreResult* result,int* error_code);
        struct ShareStoreMap* generate_new_share_store_result_get_share_store_map(struct GenerateShareStoreResult* result,int* error_code);
        void generate_share_store_result_free(struct GenerateShareStoreResult* ptr);
        struct GenerateShareStoreResult* threshold_key_generate_share(struct FFIThresholdKey* threshold_key, char* curve_n, int* error_code);
        void threshold_key_delete_share(struct FFIThresholdKey* threshold_key, char* share_index, char* curve_n, int* error_code);
        char* threshold_key_output_share(struct FFIThresholdKey* threshold_key, char* share_index, char* share_type, char* curve_n, int* error_code);
        void threshold_key_input_share(struct FFIThresholdKey* threshold_key, char* share, char* share_type, char* curve_n, int* error_code);
        //Module: security-question
        struct GenerateShareStoreResult* security_question_generate_new_share(struct FFIThresholdKey* threshold_key, char* questions, char* answer, char* curve_n, int* error_code);
        bool security_question_input_share(struct FFIThresholdKey* threshold_key, char* answer, char* curve_n, int* error_code);
        bool security_question_change_question_and_answer(struct FFIThresholdKey* threshold_key, char* questions, char* answer, char* curve_n, int* error_code);
        bool security_question_store_answer(struct FFIThresholdKey* threshold_key, char* answer, char* curve_n, int* error_code);
        char* security_question_get_answer(struct FFIThresholdKey* threshold_key, int* error_code);
        char* security_question_get_questions(struct FFIThresholdKey* threshold_key, int* error_code);
        //Module: share-transfer
        void share_transfer_store_free(struct ShareTransferStore* ptr);
        char* share_transfer_request_new_share(struct FFIThresholdKey* threshold_key, char* user_agent, char* available_share_indexes, char* curve_n, int* error_code);
        void share_transfer_add_custom_info_to_request(struct FFIThresholdKey* threshold_key, char* enc_pub_key_x, char* custom_info, char* curve_n, int* error_code);
        char* share_transfer_look_for_request(struct FFIThresholdKey* threshold_key, int* error_code);
        void share_transfer_approve_request(struct FFIThresholdKey* threshold_key, char* enc_pub_key_x, struct ShareStore* share_store, char* curve_n, int* error_code);
        void share_transfer_approve_request_with_share_indexes(struct FFIThresholdKey* threshold_key, char* enc_pub_key_x, char* share_indexes, char* curve_n, int* error_code);
        struct ShareTransferStore* share_transfer_get_store(struct FFIThresholdKey* threshold_key, int* error_code);
        bool share_transfer_set_store(struct FFIThresholdKey* threshold_key, struct ShareTransferStore* store, char* curve_n, int* error_code);
        bool share_transfer_delete_store(struct FFIThresholdKey* threshold_key, char* enc_pub_key_x, char* curve_n, int* error_code);
        char* share_transfer_get_current_encryption_key(struct FFIThresholdKey* threshold_key, int* error_code);
        struct ShareStore* share_transfer_request_status_check(struct FFIThresholdKey* threshold_key, char* enc_pub_key_x, bool delete_request_on_completion, char* curve_n, int* error_code);
        void share_transfer_cleanup_request(struct FFIThresholdKey* threshold_key, int* error_code);
        //Module:seed-phrase
        void seed_phrase_set_phrase(struct FFIThresholdKey* threshold_key,char* format,char* phrase, unsigned int number_of_wallets,char* curve_n, int* error_code);
        void seed_phrase_change_phrase(struct FFIThresholdKey* threshold_key,char* old_phrase,char* new_phrase,char* curve_n, int* error_code);
        void seed_phrase_delete_seed_phrase(struct FFIThresholdKey* threshold_key, char* seed_phrase, int* error_code);
        char* seed_phrase_get_seed_phrases(struct FFIThresholdKey* threshold_key, int* error_code);
        //(removed) char* seed_phrase_get_seed_phrases_with_accounts(struct FFIThresholdKey* threshold_key, char* derivation_path, int* error_code);
        //(removed) char* seed_phrase_get_accounts(struct FFIThresholdKey* threshold_key, char* derivation_path, int* error_code);
        //Module: private-keys
        bool private_keys_set_private_key(struct FFIThresholdKey* threshold_key, char* key, char* format, char* curve_n, int* error_code);
        char* private_keys_get_private_keys(struct FFIThresholdKey* threshold_key, int* error_code);
        char* private_keys_get_accounts(struct FFIThresholdKey* threshold_key, int* error_code);
    #ifdef __cplusplus
    } // extern "C"
    #endif
#endif // __TKEY_H__