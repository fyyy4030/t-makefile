############################################################
# Copyleft ©2018 freetoo(yigui-lu)
# name: t-makefile automatic makefile for ubuntu
# qq/wx: 48092788    e-mail: gcode@qq.com
# cn-help: https://blog.csdn.net/guestcode/article/details/81151921
# download: https://github.com/freetoo/t-makefile
# create: 2018-7-7
############################################################

# t-makefile功能说明：
#     1、自动搜索源码、头文件、库文件目录并形成有效目录列表和文件列表
#     2、自动识别总makefile功能，可批量执行子目录的makefile
#     3、自动以目录名为TTARGET文件名
#     4、可动态和静态混合链接成TARGET文件
#     5、可设置排除目录，避免搜索编译无关源码
#     6、目录框架灵活设定，框架内可自由移动子makefile仍具有自动功能
#     7、可避免链接无关符号（函数和变量），避免TARGET体积臃肿

# 使用方法（usage）： 
#     1、make                             # 正常编译 
#     2、make clean                       # 清除临时文件及TARGET文件 
#     3、make INFO=1                      # 编译时打印详细信息 
#     4、make INFO=2                      # 静默编译 
#     5、make CROSS_COMPILE=...           #交叉编译设置

# 自动makefile作用域（示例）:
# Automatic makefile scope(demo)：
#
# │───Project───│───Process───│───Module───│───Test───│
#
#	├── 01-lib
#	├── 02-com
#	├── tcp-client
#	│     ├──────── 01-lib
#	│     ├──────── 02-inc
#	│     ├──────── Module1
#	│     ├──────── Module2
#	│     │            └────────── test
#	│     │                          └──────── Makefile(test)
#	│     └──────── Makefile(Process)
#	├── tcp-server
#	├── build.mk
#	└── Makefile
#
# Makefile Scope：current directory(subdirectory) + upper common directory(subdirectory)
# Process Makefile:
# 		upper common directory = ../01-lib ../02-com
# Test Makefile:
#       upper common directory = ../../01-lib ../../02-inc ../../../01-lib ../../../02-com
# The setting of the upper common directory reference variable COMMON_DIR_NAMES
#
# makefile的作用域是：当前目录及子其目录+上层公共目录及其子目录，
# 公共目录的设置参考变量COMMON_DIR_NAMES的设置。

# 名词解释：
#   上层、向上：是指由makefile所在目录向系统根目录方向到build.mk文件
#             所在的目录位置的若干层目录。

############################################################
# 常用设置项
############################################################
# 输出目标文件名，不设置则默认使用makefile所在的目录名
# 注意：makefile要和main.c/main.cpp文件同级目录
#TARGET ?=
TARGET ?=

# 要包含的上层模块目录名列表（在makefile作用域内）
# 但要确保名称的唯一性，且为上层目录的一级目录名。
#INCLUDE_MODULE_NAMES += ModuleName
INCLUDE_MODULE_NAMES +=

# 要排除的模块目录名列表（在makefile作用域内）
#EXCLUDE_DIR_NAMES += ModuleName
EXCLUDE_MODULE_NAMES +=

# 可以手动配置变量LIB_DIRS、INC_DIRS和SRC_DIRS做补充
# 注意：是全路径名(可以用PROJECT_ROOT_DIR作为前缀就不要担心移动
#      makefile以后需要修改路径名了)，且makefile不会搜索它们的子目录
# 库文件所在目录
#LIB_DIRS += $(PROJECT_ROOT_DIR)/...
LIB_DIRS +=
# 头文件所在目录
#INC_DIRS += $(PROJECT_ROOT_DIR)/...
INC_DIRS +=
# 源码文件所在目录
#SRC_DIRS += $(PROJECT_ROOT_DIR)/...
SRC_DIRS +=

############################################################
# 编译设置部分(Compile setup part)
############################################################
# 设置调试编译选项(Setting the debug compilation options)
#DEBUG ?= y
DEBUG ?= y

# 宏定义列表(macro definition)，用于代码条件编译，不需要前面加-D，makefile会自动补上-D
#DEFS ?= DEBUG WIN32 ...
DEFS +=

# C代码编译标志(C code compile flag)
#CCFLAGS  ?= -Wall -Wfatal-errors -MMD
CCFLAGS  ?= -Wall -Wfatal-errors -MMD

# C++代码编译标志(C++ code compile flag)，注：最终CXXFLAGS += $(CCFLAGS)()
#CXXFLAGS ?= -std=c++11
CXXFLAGS ?= -std=c++11

# 编译静态库文件设置标志(Compiling a static library file setting flag)
#ARFLAGS ?= -cr
ARFLAGS ?= -cr

# 链接标志，默认纯动态链接模式(Link flag, default pure dynamic link mode)
# static  mode: DYMAMIC_LDFLAG ?=        STATIC_LDFLAGS ?=
#               DYMAMIC_LDFLAG ?= ...    STATIC_LDFLAGS ?=
# dynamic mode: DYMAMIC_LDFLAG ?=        STATIC_LDFLAGS ?= ... 
# bland   mode: DYMAMIC_LDFLAG ?= ...    STATIC_LDFLAGS ?= ... 
#
# 动态链接标志(dynamic link flag)
#DYMAMIC_LDFLAGS += -lrt -lpthread
DYMAMIC_LDFLAGS ?= -lrt -lpthread
# 静态链接标志(static link flag)
#STATIC_LDFLAGS += -lrt -Wl,--whole-archive -lpthread -Wl,--no-whole-archive
STATIC_LDFLAGS ?=

# 交叉编译设置，关联设置：CROSS_COMPILE_LIB_KEY
#CROSS_COMPILE ?= arm-linux-gnueabihf-
#CROSS_COMPILE ?= /usr/bin/arm-linux-gnueabihf-
CROSS_COMPILE ?=

# 交叉编译链库文件的关键字变量设置，用于识别交叉编译链的库文件
# 例如项目中有同样功能的库文件libcrc.a和libarm-linux-gnueabihf-crc.a，
# makefile会根据CROSS_COMPILE_LIB_KEY的设置来选择相应的库文件。
#CROSS_COMPILE_LIB_KEY ?= arm-linux-gnueabihf-
CROSS_COMPILE_LIB_KEY ?= arm-linux-gnueabihf-

############################################################
# 项目规划初期设置
############################################################
# 测试目录的目录名称，makefile会排除在搜索范围之外（makefile所在目录例外）
#TEST_DIR_NAME ?= test
TEST_DIR_NAME ?= test

# 临时目录的目录名称，makefile会排除在搜索范围之外
# 编译时临时文件（.o/.d等文件）所在的目录，如果不设置则默认为tmp
#TMP_DIR ?= tmp
TMP_DIR ?= tmp

# 要包含的上层公共目录名列表，包含库目录、头文件目录等的目录名
#COMMON_DIR_NAMES += lib inc include com comment \
#					01-lib 01-inc 01-include 01-com 01-comment \
#					02-lib 02-inc 02-include 02-com 02-comment \
#					03-lib 03-inc 03-include 03-com 03-comment
COMMON_DIR_NAMES ?= lib inc include com comment \
					01-lib 01-inc 01-include 01-com 01-comment \
					02-lib 02-inc 02-include 02-com 02-comment \
					03-lib 03-inc 03-include 03-com 03-comment

# 要排除的目录名列表
#EXCLUDE_DIR_NAMES += .git tmp temp doc docs
EXCLUDE_DIR_NAMES ?= .git tmp temp doc docs

############################################################
# TARGET设置后期处理及杂项设置
############################################################
# makefile所在目录的全路径名称
CUR_DIR ?= $(shell pwd)
# makefile所在的目录名称
CUR_DIR_NAME ?= $(notdir $(CUR_DIR))
# 如果是test目录，SRC_DIR则向上跳一层
ifeq ($(CUR_DIR_NAME),$(TEST_DIR_NAME))
SRC_DIR := $(shell dirname $(CUR_DIR))
else
SRC_DIR := $(CUR_DIR)
endif

# 如果没有手动设置TARGET，则设置为makefile所在的目录名称
ifeq ($(TARGET),)
TARGET := $(CUR_DIR_NAME)
endif

# 是编译exec文件还是库文件
IS_LIB_TARGET := $(suffix $(TARGET))
ifneq ($(IS_LIB_TARGET),)
IS_LIB_TARGET := $(shell if [ $(IS_LIB_TARGET) = .a ] || [ $(IS_LIB_TARGET) = .so ]; then echo y; fi;)
endif
ifneq ($(IS_LIB_TARGET),)
TARGET := $(if $(findstring lib,$(TARGET)),$(TARGET),lib$(TARGET))
TMP_TARGET := $(basename $(TARGET))
else
TMP_TARGET := $(TARGET)
endif

# 查找main文件
MAIN_FILE := $(shell find $(CUR_DIR) -maxdepth 1 -type f -iname 'main.c' -o -type f -iname 'main.cpp')
# 无main文件也不是编译库文件，则认为是总makefile功能
ifeq ($(MAIN_FILE)$(IS_LIB_TARGET),)
TARGET :=
MAKE_SUB := y
endif
ifeq ($(ALL),y)
MAKE_SUB := y
endif

# 编译信息显示设置，1：为全部显示，2：仅显示步骤项，其它：静默无显示
ifeq ($(INFO),1)
BUILD_INFO=
STEP_INFO=echo
else ifeq ($(INFO),2)
BUILD_INFO=@
STEP_INFO=true
else
BUILD_INFO=@
STEP_INFO=echo
endif

# 文件目录操作变量
RM      := rm -rf
MKDIR   := mkdir -p
MAKE    := make

############################################################
# 编译定义项及编译设置项的后期处理（非常用项，修改需谨慎）
############################################################

# c/c++编译器名称，默认为gcc，有cpp文件则被自动改为g++
CC  := $(CROSS_COMPILE)gcc
CXX := $(CROSS_COMPILE)g++
AR  := $(CROSS_COMPILE)ar
# 默认链接器是gcc，如果有cpp文件makefile会自动设置为g++
ifeq ($(suffix $(MAIN_FILE)),.cpp)
LD := $(CXX)
else
LD := $(CC)
endif

CCFLAGS += $(DEFS:%=-D%)
ifeq ($(DEBUG), y)
CCFLAGS += -ggdb -rdynamic -g
else
CCFLAGS += -O2 -s
endif
# 不使用到的符号不链接到目标文件中
CCFLAGS += -ffunction-sections -fdata-sections

# 链接标志和链接库设置（除TOP_MODULE_DIRS目录下的*.a和*.so文件之外的链接库设置）
# STATIC_LIB_FILES和DYNAMIC_LIB_FILES变量是makefile作用域里面的.a和.so文件列表，请一定保留
DYMAMIC_LDFLAGS := $(strip $(DYMAMIC_LDFLAGS))
STATIC_LDFLAGS := $(strip $(STATIC_LDFLAGS))
ifeq ($(DYMAMIC_LDFLAGS)$(STATIC_LDFLAGS),$(DYMAMIC_LDFLAGS))
# 纯动态链接模式
#LDFLAGS ?= -Wl,--as-needed -lrt -lpthread $(DYNAMIC_LIB_FILES) $(STATIC_LIB_FILES)
LDFLAGS ?= $(DYMAMIC_LDFLAGS) $(DYNAMIC_LIB_FILES) $(STATIC_LIB_FILES)
else ifeq ($(DYMAMIC_LDFLAGS)$(STATIC_LDFLAGS),$(STATIC_LDFLAGS))
# 纯静态链接模式
#LDFLAGS ?= -static -lrt -Wl,--whole-archive -lpthread -Wl,--no-whole-archive $(STATIC_LIB_FILES)
LDFLAGS ?= -static $(STATIC_LDFLAGS) $(STATIC_LIB_FILES)
else
# 动态静态混合链接模式
# 模板：LDFLAGS = -Wl,-Bstatic ... $(STATIC_LIB_FILES) -Wl,--as-needed -Wl,-Bdynamic ... $(DYNAMIC_LIB_FILES)
#LDFLAGS ?= -Wl,-Bstatic -lpthread $(STATIC_LIB_FILES) -Wl,--as-needed -Wl,-Bdynamic -lrt $(DYNAMIC_LIB_FILES)
LDFLAGS ?= -Wl,-Bstatic $(STATIC_LDFLAGS) $(STATIC_LIB_FILES) -Wl,-Bdynamic $(STATIC_LDFLAGS) $(DYNAMIC_LIB_FILES)
endif
LDFLAGS += -Wl,--gc-sections

# 编译动态库设置项
ifeq ($(suffix $(TARGET)),.so)
CCFLAGS += -fPIC
LDFLAGS += -shared
endif

# 最终CXXFLAGS包含CCFLAGS
CXXFLAGS += $(CCFLAGS)

# 检查编译so文件时，是否是错误设置为静态链接标志
CHECK_LDFLAGS := $(if $(findstring static,$(LDFLAGS)),'Error: build file(*.so) not use static flag',)

############################################################
# 文件和路径搜索部分（非常用项，修改需谨慎）
############################################################
INCLUDE_MODULE_NAMES := $(strip $(INCLUDE_MODULE_NAMES))
EXCLUDE_MODULE_NAMES := $(strip $(EXCLUDE_MODULE_NAMES))
COMMON_DIR_NAMES := $(strip $(COMMON_DIR_NAMES))
EXCLUDE_DIR_NAMES := $(strip $(EXCLUDE_DIR_NAMES))
SPACE :=
SPACE:= $(SPACE) $(SPACE)
EXCLUDE_DIR_NAMES += $(EXCLUDE_MODULE_NAMES)
# 不包含test目录名的排除目录名的列表
EXCLUDE_DIR_NAMES_NO_TEST := $(subst $(SPACE),\\\|,$(strip $(EXCLUDE_DIR_NAMES)))
# 要排除的目录名列表
EXCLUDE_DIR_NAMES += $(TEST_DIR_NAME)
EXCLUDE_DIR_NAMES := $(subst $(SPACE),\\\|,$(strip $(EXCLUDE_DIR_NAMES)))

# 如果是总makefile
ifneq ($(MAKE_SUB),)
# 执行make命令的makefile所在目录列表，不包含test目录
MF_MAKE_DIRS := $(dir $(shell find . -type f -iname Makefile | grep -v $(EXCLUDE_DIR_NAMES)))
MF_MAKE_DIRS := $(foreach dir,$(MF_MAKE_DIRS),$(shell if [ ! $(dir) = ./ ]; then echo $(dir); fi;))
# 执行make clean命令的makefile所在目录列表，包含test目录
MF_CLEAN_DIRS := $(dir $(shell find . -type f -iname Makefile | grep -v $(EXCLUDE_DIR_NAMES_NO_TEST)))
MF_CLEAN_DIRS := $(foreach dir,$(MF_CLEAN_DIRS),$(shell if [ ! $(dir) = ./ ]; then echo $(dir); fi;))
endif

# 包含的模块目录名列表
INCLUDE_MODULE_NAMES := $(subst $(SPACE),\\\|,$(strip $(INCLUDE_MODULE_NAMES)))

# 如果没设置临时，默认等于tmp
ifeq ($(TMP_DIR),)
TMP_DIR := tmp
endif

# 项目根目录全路径名称，即build.mk文件所在目录，如果没有build.mk则等于当前目录
PROJECT_ROOT_DIR ?= $(shell result=$(CUR_DIR); \
							for dir in $(strip $(subst /, ,$(CUR_DIR))); \
							do \
								dirs=$$dirs/$$dir; \
								if [ -f $$dirs/build.mk ]; then \
									result=$$dirs; \
									break; \
								fi; \
							done; \
							echo $$result; \
					)

# 向上搜索COMMON_DIR_NAMES指定名称的目录，库文件编译除外
ifeq ($(IS_LIB_TARGET),)
tmp := $(strip $(subst /, ,$(subst $(PROJECT_ROOT_DIR),,$(SRC_DIR))))
COMMON_DIR_NAMES := $(shell Dirs=$(PROJECT_ROOT_DIR); \
						for dir in $(tmp); \
						do \
							for name in $(COMMON_DIR_NAMES); \
							do \
								if [ -d $$Dirs/$$name ];then \
									echo $$Dirs/$$name; \
								fi; \
							done; \
							Dirs=$$Dirs/$$dir; \
						done; \
					)
ifneq ($(COMMON_DIR_NAMES),)
ALL_DIR := $(shell find $(COMMON_DIR_NAMES) -type d | grep -v $(SRC_DIR) | grep -v $(EXCLUDE_DIR_NAMES))
endif
endif

ifneq ($(INCLUDE_MODULE_NAMES),)
ALL_DIR += $(shell find $(PROJECT_ROOT_DIR) -type d | grep -v $(SRC_DIR) | grep $(INCLUDE_MODULE_NAMES) | grep -v $(EXCLUDE_DIR_NAMES))
endif
ALL_DIR += $(shell find $(SRC_DIR) -type d | grep -v $(EXCLUDE_DIR_NAMES))
ifeq ($(CUR_DIR_NAME),$(TEST_DIR_NAME))
ALL_DIR += $(shell find $(CUR_DIR) -type d | grep -v $(EXCLUDE_DIR_NAMES_NO_TEST))
endif
ALL_DIR := $(strip $(ALL_DIR))

# 去掉没有.h的目录
INC_DIRS += $(foreach dir,$(ALL_DIR),$(if $(shell find $(dir) -maxdepth 1 -type f -iname '*.h' -o -type f -iname '*.hpp'),$(dir),))
INC_DIRS := $(INC_DIRS:%=-I%)

# 源文件目录及obj文件列表
SRC_DIRS += $(foreach dir,$(ALL_DIR),$(if $(suffix $(dir)),$(shell if [ $(CUR_DIR) = $(dir) ]; then echo $(dir); fi;),$(dir)))
SRC_DIRS := $(strip $(SRC_DIRS))
SRC_DIRS := $(foreach dir,$(SRC_DIRS),$(if $(shell if [ ! $(CUR_DIR) = $(dir) ]; then find $(dir) -maxdepth 1 -type f -iname '*.a' -o -type f -iname '*.so'; fi;),,$(dir)))
SRC_DIRS := $(foreach dir,$(SRC_DIRS),$(if $(shell find $(dir) -maxdepth 1 -type f -iname '*.c' -o -type f -iname '*.cpp' | grep -v 'main.c' | grep -v 'main.cpp'),$(dir),))
OBJ_FILES := $(shell find $(SRC_DIRS) -maxdepth 1 -type f -iname '*.c' -o -type f -iname '*.cpp' | grep -v 'main.c' | grep -v 'main.cpp')
TMP_DIR := $(TMP_DIR)/
OBJ_FILES := $(OBJ_FILES:%.c=$(TMP_DIR)%.o)
OBJ_FILES := $(OBJ_FILES:%.cpp=$(TMP_DIR)%.o)
MAIN_FILE := $(MAIN_FILE:%.c=$(TMP_DIR)%.o)
MAIN_FILE := $(MAIN_FILE:%.cpp=$(TMP_DIR)%.o)

# 库文件目录
LIB_DIRS += $(foreach dir,$(ALL_DIR),$(if $(shell if [ ! $(CUR_DIR) = $(dir) ]; then find $(dir) -maxdepth 1 -type f -iname '*.a' -o -type f -iname '*.so'; fi;),$(dir),))
LIB_DIRS := $(strip $(LIB_DIRS))
# 加载so库文件的路径
LOAD_LIB_PATH := $(foreach dir,$(LIB_DIRS),$(if $(shell if [ ! $(CUR_DIR) = $(dir) ]; then find $(dir) -maxdepth 1 -type f -iname '*.so'; fi;),$(dir),))
LOAD_LIB_PATH := $(subst $(SPACE),：,$(strip $(LOAD_LIB_PATH)))

# 静态库文件列表
STATIC_LIB_FILES := $(notdir $(shell find $(LIB_DIRS) -maxdepth 1 -type f -iname '*.a'))
# 如果是交叉编译，则使用交叉编译链的库文件并排除同名的非交叉编译链的库文件
ifneq ($(CROSS_COMPILE),)
tmp := $(notdir $(shell find $(LIB_DIRS) -maxdepth 1 -type f -iname 'lib'$(CROSS_COMPILE_LIB_KEY)'*.a'))
tmp := $(subst $(CROSS_COMPILE_LIB_KEY),,$(tmp))
STATIC_LIB_FILES := $(foreach name,$(STATIC_LIB_FILES),$(if $(findstring $(CROSS_COMPILE_LIB_KEY),$(tmp)),,$(name)))
else
# 不是交叉编译链，排除交叉编译链的库文件
STATIC_LIB_FILES := $(foreach name,$(STATIC_LIB_FILES),$(if $(findstring $(CROSS_COMPILE_LIB_KEY),$(name)),,$(name)))
endif
STATIC_LIB_FILES := $(STATIC_LIB_FILES:lib%.a=-l%)

# 动态库文件列表
DYNAMIC_LIB_FILES := $(notdir $(shell find $(LIB_DIRS) -maxdepth 1 -type f -iname '*.so'))
# 如果是交叉编译，则使用交叉编译链的库文件并排除同名的非交叉编译链的库文件
ifneq ($(CROSS_COMPILE),)
tmp := $(notdir $(shell find $(LIB_DIRS) -maxdepth 1 -type f -iname 'lib'$(CROSS_COMPILE_LIB_KEY)'*.so'))
tmp := $(subst $(CROSS_COMPILE_LIB_KEY),,$(tmp))
DYNAMIC_LIB_FILES := $(foreach name,$(DYNAMIC_LIB_FILES),$(if $(findstring $(CROSS_COMPILE_LIB_KEY),$(tmp)),,$(name)))
else
# 不是交叉编译链，排除交叉编译链的库文件
DYNAMIC_LIB_FILES := $(foreach name,$(DYNAMIC_LIB_FILES),$(if $(findstring $(CROSS_COMPILE_LIB_KEY),$(name)),,$(name)))
endif
DYNAMIC_LIB_FILES := $(DYNAMIC_LIB_FILES:lib%.so=-l%)
LIB_DIRS := $(LIB_DIRS:%=-L%)
#LIB_FILES := $(DYNAMIC_LIB_FILES)
#LIB_FILES += $(STATIC_LIB_FILES)

# *.c/*/cpp文件搜索的目录，用于编译设置
#VPATH := $(SRC_DIRS)

TMP_LIB_TARGET := libtmp.a
TMP_LDFLAGS := -L$(TMP_DIR) $(TMP_LIB_TARGET:lib%.a=-l%)

############################################################
# 链接成最终文件
############################################################
all: FIRST_EXEC $(TARGET)

FIRST_EXEC:
ifdef DEB
	@echo 'TARGET:'$(TARGET)
	@echo 'TMP_TARGET:'$(TMP_TARGET)
	@echo 'CUR_DIR:'$(CUR_DIR)
	@echo 'CUR_DIR_NAME:'$(CUR_DIR_NAME)	
	@echo 'PROJECT_ROOT_DIR:'$(PROJECT_ROOT_DIR)
	@echo 'COMMON_DIR_NAMES:'$(COMMON_DIR_NAMES)
	@echo 'INCLUDE_MODULE_NAMES:'$(INCLUDE_MODULE_NAMES)
	@echo 'EXCLUDE_DIR_NAMES:'$(EXCLUDE_DIR_NAMES)
	@echo 'ALL_DIR:'$(ALL_DIR)
	@echo 'LIB_DIRS:'$(LIB_DIRS)
	@echo 'STATIC_LIB_FILES:'$(STATIC_LIB_FILES)
	@echo 'DYNAMIC_LIB_FILES:'$(DYNAMIC_LIB_FILES)
	@echo 'SRC_DIRS:'$(SRC_DIRS)
	@echo 'INC_DIRS:'$(INC_DIRS)
	@echo 'OBJ_FILES:'$(OBJ_FILES)
	@echo
endif
#*********************************************
# 总makefile模式，编译子目录下的所有makefile
ifneq ($(MF_MAKE_DIRS),)
	@$(STEP_INFO) '[step]****** submakefile is making...'
	@for dir in $(MF_MAKE_DIRS); do $(MAKE) -C $$dir; done;
	@$(STEP_INFO) '[step]****** submakefile make done'
endif

#*********************************************
# 生成exec程序
$(TMP_TARGET): $(TMP_DIR)$(TMP_LIB_TARGET) $(MAIN_FILE)
	@$(STEP_INFO) '[step]****** Building exec file: '$@
	$(BUILD_INFO)$(LD) -o $@ $^ $(TMP_LDFLAGS) $(LIB_DIRS) $(LDFLAGS)
ifneq ($(LOAD_LIB_PATH),)
	@echo '**********************************************************'
	@echo 'Please execute the following command to load the LIB(.so) path:'
	@echo 'LD_LIBRARY_PATH=$(LOAD_LIB_PATH) && export LD_LIBRARY_PATH'
endif

#*********************************************
# 生成临时静态库文件
$(TMP_DIR)$(TMP_LIB_TARGET): $(OBJ_FILES)
	@$(STEP_INFO) '[step]****** Building temp static lib file: '$@
	$(BUILD_INFO)$(AR) $(ARFLAGS) -o $@ $^

#*********************************************
# 生成静态库文件
$(TMP_TARGET).a: $(OBJ_FILES)
	@$(STEP_INFO) '[step]****** Building static lib file: '$@
	$(BUILD_INFO)$(AR) $(ARFLAGS) -o $@ $^

#*********************************************
# 生成动态库文件
$(TMP_TARGET).so: $(OBJ_FILES)
	@$(STEP_INFO) '[step]****** Building dynamic lib file: '$@
ifneq ($(CHECK_LDFLAGS),)
	@echo $(CHECK_LDFLAGS)
endif
	$(BUILD_INFO)$(LD) -o $@ $^ $(LIB_DIRS) $(LDFLAGS) $(DYNC_FLAGS)

#*********************************************
# 编译c代码文件
$(TMP_DIR)%.o: %.c
	@$(STEP_INFO) '[step]****** Compiling c file: '$<
	@$(MKDIR) $(dir $@)
	$(BUILD_INFO)$(CC) $(CCFLAGS) -c $< -o $@ $(INC_DIRS)

#*********************************************
# 编译c++代码文件
$(TMP_DIR)%.o: %.cpp
	@$(STEP_INFO) '[step]****** Compiling cpp file: '$<
	@$(MKDIR) $(dir $@)
	$(BUILD_INFO)$(CXX) $(CXXFLAGS) -c $< -o $@ $(INC_DIRS)

#*********************************************
# 头文件关联
-include $(OBJ_FILES:.o=.d)

############################################################
# 清理临时文件
############################################################
clean:
ifneq ($(MF_CLEAN_DIRS),)
# 总makefile模式
	@$(STEP_INFO) '[step]****** submakefile cleaning...'
	@for dir in $(MF_CLEAN_DIRS); do $(MAKE) -C $$dir clean; done;
	@$(STEP_INFO) '[step]****** submakefile cleaned'
endif
#*********************************************
# 子makefile模式，删除临时目录
	@if [ -d $(TMP_DIR) ]; then $(RM) -r $(TMP_DIR); fi;
	@if [ -f $(TARGET) ]; then $(RM) -f $(TARGET); fi;
	@echo '[step]****** cleaned'

.PHONY: all clean


