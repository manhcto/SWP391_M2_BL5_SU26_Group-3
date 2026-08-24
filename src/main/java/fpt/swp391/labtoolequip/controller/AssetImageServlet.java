package fpt.swp391.labtoolequip.controller;

import fpt.swp391.labtoolequip.common.AssetImageStorage;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

@WebServlet("/uploads/assets/*")
public class AssetImageServlet extends HttpServlet {
	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
		String pathInfo = request.getPathInfo();
		String fileName = pathInfo == null ? null : pathInfo.substring(1);
		Path image = AssetImageStorage.find(fileName);
		if (image == null) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;
		}
		response.setContentType(AssetImageStorage.contentType(fileName));
		response.setContentLengthLong(Files.size(image));
		Files.copy(image, response.getOutputStream());
	}
}
