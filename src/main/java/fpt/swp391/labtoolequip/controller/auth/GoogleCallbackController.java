package fpt.swp391.labtoolequip.controller.auth;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import fpt.swp391.labtoolequip.auth.AuthSession;
import fpt.swp391.labtoolequip.dao.UserDAO;
import fpt.swp391.labtoolequip.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.sql.SQLException;
import java.util.Collections;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import util.AppConfig;

@WebServlet("/oauth2/callback")
public class GoogleCallbackController extends HttpServlet {
	private static final Pattern ID_TOKEN = Pattern.compile("\"id_token\"\\s*:\\s*\"([^\"]+)\"");
	private final UserDAO userDAO = new UserDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		HttpSession session = request.getSession(false);
		String state = request.getParameter("state");
		if (session == null || state == null || !state.equals(session.getAttribute("oauthState"))) {
			response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid OAuth state.");
			return;
		}
		session.removeAttribute("oauthState");
		try {
			GoogleIdToken token = verify(exchangeCode(request.getParameter("code")));
			GoogleIdToken.Payload payload = token.getPayload();
			if (!Boolean.TRUE.equals(payload.getEmailVerified())) {
				deny(request, response, "Google email is not verified.");
				return;
			}
			String domain = required("FPT_EMAIL_DOMAIN");
			if (!payload.getEmail().toLowerCase().endsWith("@" + domain.toLowerCase())) {
				deny(request, response, "Access denied: an FPT Google account is required.");
				return;
			}
			Optional<User> found = userDAO.findByEmail(payload.getEmail());
			if (found.isEmpty() || !"ACTIVE".equals(found.get().getStatus())) {
				deny(request, response, "Access denied: account is not authorized or active.");
				return;
			}
			User user = found.get();
			if (user.getGoogleSubject() == null) {
				userDAO.bindGoogleSubject(user.getUserId(), payload.getSubject());
				user = userDAO.findById(user.getUserId()).orElseThrow();
			}
			if (!payload.getSubject().equals(user.getGoogleSubject())) {
				deny(request, response, "Access denied: Google identity does not match this account.");
				return;
			}
			AuthSession.login(request, user);
			response.sendRedirect(AuthSession.dashboard(request.getContextPath(), user.getRole()));
		} catch (InterruptedException exception) {
			Thread.currentThread().interrupt();
			throw new ServletException(exception);
		} catch (SQLException | GeneralSecurityException | RuntimeException exception) {
			throw new ServletException(exception);
		}
	}

	private String exchangeCode(String code) throws IOException, InterruptedException {
		if (code == null)
			throw new IllegalArgumentException("Missing authorization code.");
		String body = "code=" + encode(code) + "&client_id=" + encode(required("GOOGLE_CLIENT_ID")) + "&client_secret="
				+ encode(required("GOOGLE_CLIENT_SECRET")) + "&redirect_uri=" + encode(required("GOOGLE_REDIRECT_URI"))
				+ "&grant_type=authorization_code";
		HttpRequest request = HttpRequest.newBuilder(URI.create("https://oauth2.googleapis.com/token"))
				.header("Content-Type", "application/x-www-form-urlencoded")
				.POST(HttpRequest.BodyPublishers.ofString(body)).build();
		HttpResponse<String> response = HttpClient.newHttpClient().send(request, HttpResponse.BodyHandlers.ofString());
		if (response.statusCode() != 200)
			throw new IllegalStateException("Google token exchange failed.");
		Matcher matcher = ID_TOKEN.matcher(response.body());
		if (!matcher.find())
			throw new IllegalStateException("Google response did not contain an ID token.");
		return matcher.group(1);
	}

	private GoogleIdToken verify(String token) throws IOException, GeneralSecurityException {
		GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(new NetHttpTransport(),
				GsonFactory.getDefaultInstance()).setAudience(Collections.singletonList(required("GOOGLE_CLIENT_ID")))
				.setIssuers(java.util.List.of("accounts.google.com", "https://accounts.google.com")).build();
		GoogleIdToken verified = verifier.verify(token);
		if (verified == null)
			throw new IllegalArgumentException("Invalid Google ID token.");
		return verified;
	}

	private void deny(HttpServletRequest request, HttpServletResponse response, String message)
			throws ServletException, IOException {
		request.setAttribute("message", message);
		request.getRequestDispatcher("/WEB-INF/views/auth/login.jsp").forward(request, response);
	}

	private String required(String key) {
		String value = AppConfig.get(key);
		if (value == null || value.isBlank())
			throw new IllegalStateException("Missing " + key);
		return value;
	}

	private String encode(String value) {
		return URLEncoder.encode(value, StandardCharsets.UTF_8);
	}
}
