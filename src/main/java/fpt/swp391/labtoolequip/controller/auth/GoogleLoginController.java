package fpt.swp391.labtoolequip.controller.auth;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import util.AppConfig;

@WebServlet("/oauth2/google")
public class GoogleLoginController extends HttpServlet {
	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
		String clientId = AppConfig.get("GOOGLE_CLIENT_ID");
		String redirectUri = AppConfig.get("GOOGLE_REDIRECT_URI");
		if (clientId == null || redirectUri == null) {
			response.sendError(HttpServletResponse.SC_SERVICE_UNAVAILABLE, "Google login is not configured.");
			return;
		}
		String state = new LoginController().newState();
		request.getSession(true).setAttribute("oauthState", state);
		String url = "https://accounts.google.com/o/oauth2/v2/auth?client_id=" + encode(clientId) + "&redirect_uri="
				+ encode(redirectUri) + "&response_type=code&scope=" + encode("openid email profile") + "&state="
				+ encode(state) + "&prompt=select_account";
		response.sendRedirect(url);
	}

	private String encode(String value) {
		return URLEncoder.encode(value, StandardCharsets.UTF_8);
	}
}
