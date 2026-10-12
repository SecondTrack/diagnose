# Diagnose — Geräte-Testsuite für iPod touch 4 (iOS 6.1, ARMv7), Theos.
TARGET = iphone:clang:7.1:5.0
ARCHS  = armv7

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Diagnose

Diagnose_FILES  = $(wildcard src/*.m)
Diagnose_FRAMEWORKS = UIKit CoreGraphics QuartzCore Foundation CoreMotion AVFoundation AudioToolbox
Diagnose_CFLAGS  = -fobjc-arc -O2 -Wall

include $(THEOS_MAKE_PATH)/application.mk
