package util;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import jakarta.servlet.http.Part;
import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;

public class CloudinaryUtil {
	private static Cloudinary cloudinary;

	static {
		try {
			String url = AppConfig.get("CLOUDINARY_URL");
			if (url != null && !url.isBlank()) {
				cloudinary = new Cloudinary(url);
			} else {
				String cloudName = AppConfig.get("CLOUDINARY_CLOUD_NAME");
				String apiKey = AppConfig.get("CLOUDINARY_API_KEY");
				String apiSecret = AppConfig.get("CLOUDINARY_API_SECRET");
				if (isBlank(cloudName) || isBlank(apiKey) || isBlank(apiSecret)) {
					System.err.println("WARNING: Cloudinary is not configured; image upload is disabled.");
				} else {
					Map<String, String> config = new HashMap<>();
					config.put("cloud_name", cloudName);
					config.put("api_key", apiKey);
					config.put("api_secret", apiSecret);
					cloudinary = new Cloudinary(config);
				}
			}
		} catch (Exception e) {
			System.err.println("WARNING: Failed to initialize Cloudinary client: " + e.getMessage());
		}
	}

	private CloudinaryUtil() {
	}

	private static boolean isBlank(String value) {
		return value == null || value.isBlank();
	}

	/**
	 * Upload an image Part to Cloudinary.
	 *
	 * @param part
	 *            the multipart/form-data Part
	 * @param folder
	 *            the folder on Cloudinary (e.g. "labtoolequip/maintenance")
	 * @return the secure HTTPS URL of the uploaded image, or null if no file was
	 *         uploaded
	 */
	public static String uploadImage(Part part, String folder) throws IOException {
		if (part == null || part.getSize() == 0) {
			return null;
		}

		String submittedFileName = part.getSubmittedFileName();
		if (submittedFileName == null || submittedFileName.isBlank()) {
			return null;
		}

		// Ensure it's an image
		String contentType = part.getContentType();
		if (contentType != null && !contentType.startsWith("image/")) {
			throw new IllegalArgumentException("Chỉ chấp nhận tệp hình ảnh (PNG, JPG, JPEG, WEBP)!");
		}

		// Max 10MB limit
		if (part.getSize() > 10 * 1024 * 1024) {
			throw new IllegalArgumentException("Dung lượng hình ảnh không được vượt quá 10MB!");
		}

		if (cloudinary == null) {
			throw new IllegalStateException("Cloudinary chưa được cấu hình!");
		}

		try (InputStream inputStream = part.getInputStream()) {
			byte[] bytes = inputStream.readAllBytes();
			Map<String, Object> params = ObjectUtils.asMap("folder",
					folder != null ? folder : "labtoolequip/maintenance", "resource_type", "auto");
			Map<?, ?> uploadResult = cloudinary.uploader().upload(bytes, params);
			return (String) uploadResult.get("secure_url");
		}
	}
}
