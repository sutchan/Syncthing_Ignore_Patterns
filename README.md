# Syncthing Ignore Patterns

Syncthing 同步工具的忽略清单位于各同步目录内的 .stignore

可在Syncthing配置文件的忽略清单里设置，或编辑 .stignore 来设置。


支持的通配符的简单教程：

(?d)     表示如果删除了阻止目录则文件可被删除的前缀

(?i)     表示该模式匹配忽略了大小写差异的前缀

!        对本条件取反（例如：不要排除某项）

*         单级通配符（仅匹配单层文件夹）

**        多级通配符（用以匹配多层文件夹）

//       注释，在行首使用



支持的通配符的完整教程
2.14 忽略文件
2.14.1. Synopsis
.stignore
2.14.2. Description
如果某些文件不应与其他设备同步， .stignore则可以创建一个包含要忽略的文件模式的文件。该 .stignore文件必须放在该文件夹的根目录中。该 .stignore文件本身不会被同步到其他设备，虽然它可以 #include是文件的设备之间同步。所有模式都与文件夹根目录相关。

注意

请注意，被忽略的文件可以阻止删除其他空目录。请参阅下面的（？d）前缀以允许删除被忽略的文件。

2.14.3. Patterns
该.stignore文件包含文件或路径模式的列表。匹配的 第一个模式将决定给定文件的命运。

常规文件名自身匹配，即模式foo匹配文件foo，subdir/foo以及任何名为的目录 foo。空格被视为常规字符。
星号匹配文件名中的零个或多个字符，但与目录分隔符不匹配。te*st匹配test， subdir/telerest但不是tele/rest。
双星号匹配如上，但也是目录分隔符。 te**st比赛test，subdir/telerest和 tele/sub/dir/rest。
问号匹配不是目录分隔符的单个字符。te??st匹配tebest但不是teb/st或 test。
括在方括号[]中的字符被解释为字符范围[a-z]。在使用此语法之前，您应该对正则表达式字符类有基本的了解。
/仅以当前目录中的匹配开头的模式。 /foo匹配foo但不是subdir/foo。
从开始的模式#include导致从命名文件加载模式。文件不存在或被包含多次是错误的。请注意，虽然这可以用于包含子目录中文件的模式，但模式本身仍然相对于文件夹根目录。示例： 。#include more-patterns.txt
以!前缀开头的模式会否定模式：包含匹配文件（即，不会忽略）。这可以用于覆盖后面的更一般的模式。
以(?i)前缀开头的模式允许不区分大小写的模式匹配。(?i)test比赛test，TEST和tEsT。该 (?i)前缀可以与其他图案进行组合，例如，图案(?i)!picture*.png指示Picture1.PNG应被同步。在Mac OS和Windows上，模式始终不区分大小写。
以(?d)前缀开头的模式可以删除这些文件（如果它们阻止删除目录）。任何操作系统生成的文件都应该使用此前缀，您很乐意将其删除。
以...开头的行//是无效的。
Windows不支持转义。\[foo - bar\]
注意

前缀可以按任何顺序指定（例如“（？d）（？i）”），但不能在一对括号中（不是“ （？di） ”）。

2.14.4. Example
给定目录布局：

.DS_Store
foo
foofoo
bar/
    baz
    quux
    quuz
bar2/
    baz
    frobble
My Pictures/
    Img15.PNG
以及.stignore包含以下内容的文件：

(?d).DS_Store
!frobble
!quuz
foo
*2
qu*
(?i)my pictures
所有名为“foo”的文件和目录，以“2”结尾或以“qu”开头都将被忽略。最终结果变为：

.DS_Store     # ignored, will be deleted if gets in the way of parent directory removal
foo           # ignored, matches "foo"
foofoo        # synced, does not match "foo" but would match "foo*" or "*foo"
bar/          # synced
    baz       # synced
    quux      # ignored, matches "qu*"
    quuz      # synced, matches "qu*" but is excluded by the preceding "!quuz"
bar2/         # ignored, matched "*2"
    baz       # ignored, due to parent being ignored
    frobble   # ignored, due to parent being ignored; "!frobble" doesn't help
My Pictures/  # ignored, matched case insensitive "(?i)my pictures" pattern
    Img15.PNG # ignored, due to parent being ignored
注意

请注意，以斜杠结尾的目录模式 some/directory/匹配目录的内容，但不匹配目录本身。如果您希望模式与目录及其内容匹配，请确保它/在模式的末尾没有。
