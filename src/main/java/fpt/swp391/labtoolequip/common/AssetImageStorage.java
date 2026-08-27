package fpt.swp391.labtoolequip.common;

import jakarta.servlet.http.Part;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

/** Stores user-uploaded equipment images outside the deployed WAR. */
public final class AssetImageStorage {
	private static final long MAX_IMAGE_BYTES = 5L * 1024 * 1024;
	private static final Set<String> EXTENSIONS = Set.of("jpg", "jpeg", "png", "webp");
	private static final Path DIRECTORY = Path.of(System.getProperty("user.home"), ".lab-asset", "uploads", "assets");

	private AssetImageStorage() {
	}

	public static String save(Part part) throws IOException {
		if (part == null || part.getSize() == 0) {
			return null;
		}
		String extension = extension(part.getSubmittedFileName());
		if (!isSupported(part.getSubmittedFileName(), part.getContentType())) {
			throw new IllegalArgumentException("Ảnh phải có định dạng JPG, PNG hoặc WebP.");
		}
		if (part.getSize() > MAX_IMAGE_BYTES) {
			throw new IllegalArgumentException("Mỗi ảnh không được vượt quá 5 MB.");
		}
		Files.createDirectories(DIRECTORY);
		String fileName = UUID.randomUUID() + "." + extension;
		try (InputStream input = part.getInputStream()) {
			Files.copy(input, DIRECTORY.resolve(fileName), StandardCopyOption.REPLACE_EXISTING);
		}
		return "/uploads/assets/" + fileName;
	}

	public static void delete(String imagePath) {
		String fileName = fileName(imagePath);
		if (fileName == null) {
			return;
		}
		try {
			Files.deleteIfExists(DIRECTORY.resolve(fileName));
		} catch (IOException ignored) {
			// The database operation already failed; leave cleanup for the next manual
			// review.
		}
	}

	public static Path find(String fileName) {
		if (fileName == null || !fileName.matches("[0-9a-f-]+\\.(jpg|jpeg|png|webp)")) {
			return null;
		}
		Path image = DIRECTORY.resolve(fileName).normalize();
		return image.startsWith(DIRECTORY) && Files.isRegularFile(image) ? image : null;
	}

	public static String contentType(String fileName) {
		String extension = extension(fileName);
		return switch (extension) {
			case "jpg", "jpeg" -> "image/jpeg";
			case "png" -> "image/png";
			case "webp" -> "image/webp";
			default -> "application/octet-stream";
		};
	}

	static boolean isSupported(String fileName, String contentType) {
		String extension = extension(fileName);
		if (!EXTENSIONS.contains(extension) || contentType == null) {
			return false;
		}
		return contentType.equalsIgnoreCase(contentType(fileName));
	}

	private static String fileName(String imagePath) {
		if (imagePath == null || !imagePath.startsWith("/uploads/assets/")) {
			return null;
		}
		String fileName = imagePath.substring("/uploads/assets/".length());
		return find(fileName) == null ? null : fileName;
	}

	private static String extension(String fileName) {
		if (fileName == null) {
			return "";
		}
		int dot = fileName.lastIndexOf('.');
		return dot < 0 ? "" : fileName.substring(dot + 1).toLowerCase(Locale.ROOT);
	}
}
