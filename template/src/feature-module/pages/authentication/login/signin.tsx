// src/pages/authentication/Signin.tsx
import React, { useState } from "react";
import { Link } from "react-router-dom";
import { all_routes } from "../../../../routes/all_routes";
import {
    appleLogo,
    facebookLogo,
    googleLogo,
    logoPng,
    logoWhitePng
} from "../../../../utils/imagepath";
import { useNavigate } from "react-router";
import { setCredentials } from "../../../../core/redux/authSlice.ts";
import { useAlert } from "../../../../components/AlertContext.tsx";
import { useDispatch } from "react-redux";
import { AuthService } from "../../../../services/authService.ts";

const Signin: React.FC = () => {
    const [isPasswordVisible, setPasswordVisible] = useState<boolean>(false);
    const navigate = useNavigate();
    const { showAlert } = useAlert();
    const [username, setUsername] = useState("");
    const [password, setPassword] = useState("");
    const [loading, setLoading] = useState(false); // ✅ Loading state eklendi
    const dispatch = useDispatch();

    const togglePasswordVisibility = (): void => {
        setPasswordVisible((prevState: boolean) => !prevState);
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();

        // ✅ Validasyon
        if (!username || !password) {
            showAlert({
                type: "warning",
                message: "Kullanıcı adı ve şifre zorunludur",
                autoClose: 3000,
            });
            return;
        }

        setLoading(true);

        try {
            // ✅ BACKEND LOGIN REQUEST
            const response: any = await AuthService.login({
                username,
                password,
            });

            console.log("✅ Login Response:", response);
            // Backend token'i response.payload.accessToken olarak veriyorsa
            const accessToken: any = response.payload?.accessToken;
            
            const user = response.payload?.user ?? null;

            if (!accessToken) {
                throw new Error("Token bulunamadı");
            }



            // ✅ REDUX STATE'E KAYDET
            dispatch(setCredentials({ accessToken, user }));

            // ✅ SUCCESS ALERT
            showAlert({
                type: "success",
                message: "Giriş başarılı! Yönlendiriliyorsunuz...",
                autoClose: 2000,
            });

            // ✅ STOREFRONT'A GİT (2 saniye sonra)
            setTimeout(() => {
                navigate("/store");
            }, 2000);

        } catch (error: any) {
            console.error("❌ Login Hatası:", error);

            // ✅ ERROR ALERT
            showAlert({
                type: "danger",
                message: error?.response?.data?.message || "Giriş başarısız. Bilgilerinizi kontrol edin.",
                autoClose: 5000,
            });

            // ❌ HATA ALINCA DASHBOARD'A GİTME
            // navigate("/dashboard"); // ← Kaldırıldı

            // ✅ Username ve password KALSIN (state değişmedi)
        } finally {
            setLoading(false);
        }
    };

    const route = all_routes;

    return (
        <>
            {/* Main Wrapper */}
            <div className="main-wrapper">
                <div className="account-content">
                    <div className="login-wrapper bg-img">
                        <div className="login-content authent-content">
                            <form onSubmit={handleSubmit}>
                                <div className="login-userset">
                                    <div className="login-logo logo-normal">
                                        <img src={logoPng} alt="img" />
                                    </div>
                                    <Link to={route.dashboard} className="login-logo logo-white">
                                        <img src={logoWhitePng} alt="Img" />
                                    </Link>
                                    <div className="login-userheading">
                                        <h3>Sign In</h3>
                                        <h4 className="fs-16">
                                            Access the Dreamspos panel using your email and passcode.
                                        </h4>
                                    </div>

                                    {/* Email/Username */}
                                    <div className="mb-3">
                                        <label className="form-label">
                                            Email <span className="text-danger"> *</span>
                                        </label>
                                        <div className="input-group">
                                            <input
                                                type="text"
                                                value={username}
                                                onChange={(e) => setUsername(e.target.value)}
                                                className="form-control border-end-0"
                                                placeholder="admin@example.com"
                                                disabled={loading} // ✅ Loading sırasında disable
                                            />
                                            <span className="input-group-text border-start-0">
                        <i className="ti ti-mail" />
                      </span>
                                        </div>
                                    </div>

                                    {/* Password */}
                                    <div className="mb-3">
                                        <label className="form-label">
                                            Password <span className="text-danger"> *</span>
                                        </label>
                                        <div className="pass-group">
                                            <input
                                                type={isPasswordVisible ? "text" : "password"}
                                                value={password}
                                                onChange={(e) => setPassword(e.target.value)}
                                                className="pass-input form-control"
                                                placeholder="Enter your password"
                                                disabled={loading} // ✅ Loading sırasında disable
                                            />
                                            <span
                                                className={`ti toggle-password text-gray-9 ${
                                                    isPasswordVisible ? "ti-eye" : "ti-eye-off"
                                                }`}
                                                onClick={togglePasswordVisibility}
                                                style={{
                                                    cursor: loading ? "not-allowed" : "pointer",
                                                    opacity: loading ? 0.5 : 1
                                                }}
                                            ></span>
                                        </div>
                                    </div>

                                    {/* Remember Me & Forgot Password */}
                                    <div className="form-login authentication-check">
                                        <div className="row">
                                            <div className="col-12 d-flex align-items-center justify-content-between">
                                                <div className="custom-control custom-checkbox">
                                                    <label className="checkboxs ps-4 mb-0 pb-0 line-height-1 fs-16 text-gray-6">
                                                        <input
                                                            type="checkbox"
                                                            className="form-control"
                                                            disabled={loading}
                                                        />
                                                        <span className="checkmarks" />
                                                        Remember me
                                                    </label>
                                                </div>
                                                <div className="text-end">
                                                    <Link
                                                        className="text-orange fs-16 fw-medium"
                                                        to={route.forgotPassword}
                                                    >
                                                        Forgot Password?
                                                    </Link>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    {/* Submit Button */}
                                    <div className="form-login">
                                        <button
                                            type="submit"
                                            className="btn btn-primary w-100"
                                            disabled={loading}
                                        >
                                            {loading ? (
                                                <>
                                                    <span className="spinner-border spinner-border-sm me-2" />
                                                    Signing In...
                                                </>
                                            ) : (
                                                "Sign In"
                                            )}
                                        </button>
                                    </div>

                                    {/* Create Account */}
                                    <div className="signinform">
                                        <h4>
                                            New on our platform?
                                            <Link to={route.register} className="hover-a">
                                                {" "}
                                                Create an account
                                            </Link>
                                        </h4>
                                    </div>

                                    {/* Social Login */}
                                    <div className="form-setlogin or-text">
                                        <h4>OR</h4>
                                    </div>
                                    <div className="mt-2">
                                        <div className="d-flex align-items-center justify-content-center flex-wrap">
                                            <div className="text-center me-2 flex-fill">
                                                <Link
                                                    to="#"
                                                    className="br-10 p-2 btn btn-info d-flex align-items-center justify-content-center"
                                                    onClick={(e) => {
                                                        e.preventDefault();
                                                        showAlert({
                                                            type: "info",
                                                            message: "Facebook login coming soon!",
                                                            autoClose: 2000,
                                                        });
                                                    }}
                                                >
                                                    <img
                                                        className="img-fluid m-1"
                                                        src={facebookLogo}
                                                        alt="Facebook"
                                                    />
                                                </Link>
                                            </div>
                                            <div className="text-center me-2 flex-fill">
                                                <Link
                                                    to="#"
                                                    className="btn btn-white br-10 p-2 border d-flex align-items-center justify-content-center"
                                                    onClick={(e) => {
                                                        e.preventDefault();
                                                        showAlert({
                                                            type: "info",
                                                            message: "Google login coming soon!",
                                                            autoClose: 2000,
                                                        });
                                                    }}
                                                >
                                                    <img
                                                        className="img-fluid m-1"
                                                        src={googleLogo}
                                                        alt="google"
                                                    />
                                                </Link>
                                            </div>
                                            <div className="text-center flex-fill">
                                                <Link
                                                    to="#"
                                                    className="bg-dark br-10 p-2 btn btn-dark d-flex align-items-center justify-content-center"
                                                    onClick={(e) => {
                                                        e.preventDefault();
                                                        showAlert({
                                                            type: "info",
                                                            message: "Apple login coming soon!",
                                                            autoClose: 2000,
                                                        });
                                                    }}
                                                >
                                                    <img
                                                        className="img-fluid m-1"
                                                        src={appleLogo}
                                                        alt="Apple"
                                                    />
                                                </Link>
                                            </div>
                                        </div>
                                    </div>

                                    {/* Copyright */}
                                    <div className="my-4 d-flex justify-content-center align-items-center copyright-text">
                                        <p>Copyright © 2025 DreamsPOS</p>
                                    </div>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
            {/* /Main Wrapper */}
        </>
    );
};

export default Signin;