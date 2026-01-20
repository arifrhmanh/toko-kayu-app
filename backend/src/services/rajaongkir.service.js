const axios = require('axios');

const RAJAONGKIR_API_KEY = process.env.RAJAONGKIR_API_KEY;
const BASE_URL = 'https://rajaongkir.komerce.id/api/v1';

// ID Provinsi Jawa Timur
const JAWA_TIMUR_PROVINCE_ID = '18';

/**
 * Get all cities in Jawa Timur province
 * @returns {Promise<Array>}
 */
async function getKotaJawaTimur() {
    try {
        const response = await axios.get(`${BASE_URL}/destination/city/${JAWA_TIMUR_PROVINCE_ID}`, {
            headers: {
                key: RAJAONGKIR_API_KEY
            }
        });

        if (response.data.meta.code === 200) {
            return response.data.data.map(city => ({
                id: city.id.toString(),
                nama: city.name
            }));
        }

        return [];
    } catch (error) {
        console.error('Raja Ongkir get cities error:', error.response?.data || error.message);
        return [];
    }
}

/**
 * Get kecamatan (district) by kota (city) ID
 * @param {string} kotaId - City ID
 * @returns {Promise<Array>}
 */
async function getKecamatanByKota(kotaId) {
    try {
        const response = await axios.get(`${BASE_URL}/destination/district/${kotaId}`, {
            headers: {
                key: RAJAONGKIR_API_KEY
            }
        });

        if (response.data.meta.code === 200) {
            return response.data.data.map(district => ({
                id: district.id.toString(),
                nama: district.name
            }));
        }

        return [];
    } catch (error) {
        console.error('Raja Ongkir get districts error:', error.response?.data || error.message);
        return [];
    }
}

/**
 * Get kelurahan (sub-district) by kecamatan (district) ID
 * @param {string} kecamatanId - District ID
 * @returns {Promise<Array>}
 */
async function getKelurahanByKecamatan(kecamatanId) {
    try {
        const response = await axios.get(`${BASE_URL}/destination/sub-district/${kecamatanId}`, {
            headers: {
                key: RAJAONGKIR_API_KEY
            }
        });

        if (response.data.meta.code === 200) {
            return response.data.data.map(subDistrict => ({
                id: subDistrict.id.toString(),
                nama: subDistrict.name,
                kode_pos: subDistrict.zip_code || null
            }));
        }

        return [];
    } catch (error) {
        console.error('Raja Ongkir get sub-districts error:', error.response?.data || error.message);
        return [];
    }
}

module.exports = {
    getKotaJawaTimur,
    getKecamatanByKota,
    getKelurahanByKecamatan,
    JAWA_TIMUR_PROVINCE_ID
};
