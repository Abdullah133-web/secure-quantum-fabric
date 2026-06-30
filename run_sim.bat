@echo off
echo 🚀 Compiling Quantum Security Fabric...
iverilog -o sim_output.vvp src/secure_fabric_top.v src/secure_fabric_core.v src/tb_secure_fabric.v
if %errorlevel% equ 0 (
    echo ✅ Compilation Successful! Generating waveforms...
    vvp sim_output.vvp
    echo 📊 Done! Open 'dump.vcd' in GTKWave to see the timeline.
) else (
    echo ❌ Compilation failed. Make sure Icarus Verilog is installed on your Windows PC.
)
