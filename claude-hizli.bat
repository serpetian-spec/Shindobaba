@echo off
rem Claude Code'u izin sorusu sormadan baslatir (yalniz bu proje klasorunde).
cd /d "%~dp0"
claude --dangerously-skip-permissions %*
