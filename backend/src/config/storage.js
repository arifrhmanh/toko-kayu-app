const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_KEY;

if (!supabaseUrl || !supabaseKey) {
    console.warn('Warning: Supabase credentials not configured');
}

const supabase = createClient(supabaseUrl || '', supabaseKey || '');

// Storage bucket name for product images
const STORAGE_BUCKET = 'produk-images';

/**
 * Initialize storage bucket if not exists
 */
async function initializeStorage() {
    try {
        const { data: buckets } = await supabase.storage.listBuckets();
        const bucketExists = buckets?.some(b => b.name === STORAGE_BUCKET);

        if (!bucketExists) {
            const { error } = await supabase.storage.createBucket(STORAGE_BUCKET, {
                public: true,
                fileSizeLimit: 5242880 // 5MB
            });

            if (error) {
                console.error('Error creating storage bucket:', error);
            } else {
                console.log('Storage bucket created:', STORAGE_BUCKET);
            }
        }
    } catch (error) {
        console.error('Error initializing storage:', error);
    }
}

/**
 * Upload file to Supabase Storage
 * @param {Buffer} fileBuffer - File buffer
 * @param {string} fileName - File name
 * @param {string} mimeType - File MIME type
 * @returns {Promise<{url: string, path: string} | null>}
 */
async function uploadFile(fileBuffer, fileName, mimeType) {
    try {
        const filePath = `${Date.now()}-${fileName}`;

        const { data, error } = await supabase.storage
            .from(STORAGE_BUCKET)
            .upload(filePath, fileBuffer, {
                contentType: mimeType,
                upsert: false
            });

        if (error) {
            console.error('Upload error:', error);
            return null;
        }

        // Get public URL
        const { data: urlData } = supabase.storage
            .from(STORAGE_BUCKET)
            .getPublicUrl(filePath);

        return {
            url: urlData.publicUrl,
            path: filePath
        };
    } catch (error) {
        console.error('Upload error:', error);
        return null;
    }
}

/**
 * Delete file from Supabase Storage
 * @param {string} filePath - File path in storage
 * @returns {Promise<boolean>}
 */
async function deleteFile(filePath) {
    try {
        const { error } = await supabase.storage
            .from(STORAGE_BUCKET)
            .remove([filePath]);

        if (error) {
            console.error('Delete error:', error);
            return false;
        }

        return true;
    } catch (error) {
        console.error('Delete error:', error);
        return false;
    }
}

/**
 * Extract file path from public URL
 * @param {string} url - Public URL
 * @returns {string | null}
 */
function getFilePathFromUrl(url) {
    if (!url) return null;

    try {
        const urlParts = url.split(`/storage/v1/object/public/${STORAGE_BUCKET}/`);
        return urlParts[1] || null;
    } catch {
        return null;
    }
}

module.exports = {
    supabase,
    STORAGE_BUCKET,
    initializeStorage,
    uploadFile,
    deleteFile,
    getFilePathFromUrl
};
