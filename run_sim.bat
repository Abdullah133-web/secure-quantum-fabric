@echo off
echo ===================================================
echo   Compiling Secure Quantum Fabric Architecture...
echo ===================================================

iverilog -o sim_output.vvp src/sbox_transform.v src/key_expansion.v src/state_transforms.v src/secure_fabric_core.v src/secure_fabric_top.v src/tb_secure_fabric.v

if %errorlevel% neq 0 (
    echo [ERROR] Compilation failed! Check syntax errors above.
    pause
    exit /b %errorlevel%
)

echo [SUCCESS] Compilation complete. Running simulation engine...
vvp sim_output.vvp
echo [SUCCESS] Simulation complete. Waveform database generated.
