### Dancing-Links 算法可视化   

* 运行环境   
  Strawberry Perl V5.24 （或以上）   
  通常 Strawberry Perl 自带 OpenGL 和 Imager，如果没有相关模块则需要安装后才可运行。   

* 记录   
  * 动画实现   
    由于 glut 采用回调的形式管理闲时、显示函数，而 DancingLinks 算法一般用递归实现，而且流程略微复杂，   
    将过程用动画展示并不方便，于是借用了 threads 模块单独开一个线程，threads::shared 模块将关键数据线程共享。   

  * 文字显示   
    列标和行标的字符，用 Imager 生成像素数据，将RGBA分量分解到 @rasters 数组，然后借 OpenGL::Array 将数据
    转为 C 指针对象，传入 glDrawPixels_c 函数绘制。   

  * RandMatrix.pm   
    用于生成能够精确覆盖的矩阵，并掺入随机的行作为题目。   

  * DancingLinks.pm   
    数据转十字链表、打印链表。   

  动态演示：   
  ![](DancingLinks_Visual.gif)   

  添加文字描述：   
  ![](DancingLinks_Visual.png)    

