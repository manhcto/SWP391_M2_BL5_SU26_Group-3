package fpt.swp391.labtoolequip.controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet({"/admin/lab-rules", "/lab-manager/lab-rules", "/mentor/lab-rules", "/intern/lab-rules"})
public class LabRulesController extends HttpServlet {
	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		String path = request.getRequestURI().substring(request.getContextPath().length());
		request.setAttribute("roleBase", path.substring(0, path.indexOf("/lab-rules")));
		request.getRequestDispatcher("/WEB-INF/views/shared/lab-rules.jsp").forward(request, response);
	}
}
