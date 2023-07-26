# Z-AI V1.4 发行版本 

**简单介绍**

- 被ZNet,ZDB2,Code模型,AI-Tech2022,众多新技术体系加持
- 相比1.3系,这是接近于重构的升级
- 生产建模端工具链逼近400个
- 接近150个AI相关Demo
- 没有AI建模限制
- 更多请阅读 [详情](https://zpascal.net/ZAI%201.4%E6%9B%B4%E6%96%B0%E6%97%A5%E5%BF%972023_7.pdf)

# 开源项目定位

**开源版本可以自由获取,自由建模,自己解决识别问题,而项目框架设计,底座和平台化,落地等环节并不开源,也不提供文档**

# 1.4 AI算法体系

算法体系由算法api+算法支持组成,算法支持是指运行算法条件,例如建模系统,算法应用思路,比如dnn-thread系统就是一种算法支持,样本数据库也是一种算法支持,基于样本数据库搭建的建模工具也是一种支持.

算法api这一部分就是大家在git接触各种CV+识别性质的开源项目.ZAI会有些自主创新,而算法思路和方向,与这些开源项目基本算一致,甚至一些开源项目比ZAI的算法更加先进,识别率也会更高.看开源项目是看更新强度,持续的强更新才能真正推进到社会生产和应用,否则会被时间洗掉.

在ZAI的早期版本(1.2/1.3),一直很注重算法体系的建设,基本每次更新,都会增加一大堆新算法.后来做完发行版本以后,这些算法加在一起,已经可以等同于数十个开源项目了,同时这些算法大部分都没有被应用.这就很尴尬!因为应用最多的只有,目标检测,目标分类,场景分类,其余算法基本不会应用,即使再增加几十种算法,也不会改变什么,例如把yolov7加进来也会一样.在计算引擎集成多个同性质算法无意义,这并不会改变应用模式,也不会改变建模成果和项目成败.

算法与实际项目的匹配性其实非常小,而我们通过百度,虹软,商汤,这类公司使用的AI方案都是挖空心思做出来的,这并不是算法层面的.这些公司,他们有自己的技术体系,以及,应用层思路,算法是一种资源,算法的命运是被技术体系筛选和重构.算法的方案性占比非常小.算法周边的体系,这才是AI类公司赖以生存的核心.换个角度来说,AI公司靠时代红利生存,算法是AI公司吃下去的食物,框架和算法支持体系是AI公司的消化系统,最后,产出各种应用方案.

明确了算法的本质定位以后,回到ZAI的算法体系中,算法的核心是算法支持体系,在此之后,才是建立应用层框架落地.

ZAI的算法支持体系部分,经历了3年洗礼,现在,ZAI正在走出自己的路线.

## 1.4 AI数据库体系

AI数据库体系只能适用建模体系,例如场景分类器的样本最少也会上万张720p/1080p,稍微堆大一点,这些样本回答道百万级规模.这时候,大数据管理,高效存取必须使用服务器硬件设备,例如大内存,>20核的cpu.这对于数据库技术有一定要求.

AI数据库体系并不是传统数据库,而是程序级的数据结构,这些数据结构一律支持多线程加速,以及Large-Scale(TB级大数据支持体系).传统mis/erp开发用的pc无法适应AI数据库:样本规模一旦大了,内存就不够了,必须精简or使用Large-Scale方式来管理数据库,这会导致浪费大把时间去干一些和硬件较劲的无意义工作.

AI数据库结构=适应所有的模型的数据要求的+样本链结构+样本链矩阵结构

AI数据库体系=Z.AI.Common(AI数据库)+Z.AI.Editor(AI工具链副本数据库)+*.dproj(整个建模工具链体系,大约20-30个建模支持工具),这些数据库在存储底层大量使用DFE,ZDB1,ZDB2工具形式支持库.

AI数据库体系不区分目标模型,但凡模型凡需要的数据都会在AI数据库体系对应支持,这些支持包括API支持,规范化支持,工具链支持.

## 1.4 AI工具链体系

由于项目的开发,AI工具链一直作为内部版本在更新.

撰写本文时,工具链已经构建了接近150个版本,历经大量修复+更新.

版本计数历史自1.4 Eval1..Eval9(这里走了90%版本数量)

之后, Beta1..Beta3(这时候,已经逼近2023-6月出发行版本时间计划)

## 1.4 AI平台和底座类体系

提示:**开源版本不包含平台支持技术**

简单来说:**只能使用AI建模和识别,应用落地靠自己解决**

## 1.4 引入ZDB2体系

首先,明确ZDB2的未来使用路线:大数据底层地基
	
其次,明确大数据问题solve:数据库引擎必须遵守计算机机理,数据库应用场景永远不确定,数据库不会是一套体系解决一切数据问题,ZDB2认为:解决数据库问题就要自己设计数据库引擎,在所有的项目中都要使用独特自主设计的数据库引擎.
	
**ZDB2体系的技术路线推进回顾**

1. 给出ZDB2底层空间表支持系统:解决数据块的增删存改问题
2. 在空间表支持系统基础上,尝试过小规模应用,例如C4系统中的UserDB,FileDB,效果平平
3. 开始自我反思,之后,给出了线程化存储引擎体系,从底层机制来看待,ZDB2此时已经具备大规模存储支持能力.
4. 支持了线程化存储引擎后,在落地项目应用,将数据库构建与数据中心服务器群集.
5. 在数据中心运营过程,ZDB2被地狱级难度洗礼,同时也具备了新属性,包括可扩展性,数据安全性,增强自定义数据库设计.在6代监控系统,ZDB2完成了单日PB级数据量驱动,在无人维护环境中持续3个月不重启,不关机.
6. 走出地狱,面向阳光,坚持走数据库=自定义数据引擎的底层逻辑.

### ZDB2的后续动作:未来会持续更新

暂时没有放到前台推广计划,但会开源ZDB2,也会提供一些相关Demo.底层逻辑是因为我是程序员,我与世界的关系就是世界需要我的贡献,同时世界也在随时计算和剽窃我,但世界不能阻挡我的贡献行为,长久以来我和世界都是一种相互踩平衡木的关系,这也是只开源技术,而不开源项目的初衷:拥抱技术,建立开源过滤机制.

因为ZDB2具备了大数据支持能力,未来高几率会在某些条件成立时,在底层会给出非常棒的数据地基.只有自定义数据引擎才能胜任一切需求.

## 1.4 引入并大幅优化ZNet体系

ZNet代表整个后台服务器体系,以ZNet为基础的上层架构.

- 详情去看git, https://github.com/PassByYou888/ZNet
- p2pVM是新一代通讯底层:替代物理socket
- C4代表大型服务器:替代双通道交互,提供大规模后台地基

从宏观来看,C4体系+ZDB2体系+BigList体系+Core体系

这套组合拳只能在1.4或未来的版本使用.

ZDB2后台系统的数据引擎是独特的,ZNet后台服务器几乎全部工作于线程模型(凡处理延迟大于100ms的请求都用线程拉),BigList体系为数据链带来大容量提升,C4为服务器后台提供了高级架构.

pas圈子有许多以设计模式为工作路线的程序员,他们为广大入门者带来了傻瓜化的后台框架,他们有非常深厚的计算机理论基础.这造成了一个局面:使用者和设计者是依赖关系,不是完全性互相依赖,当设计者不能自我提升时,使用者就会被动.反应在真实生活和工作中就是当世界出现新事物的征兆,有许多人发现了它,但设计者无法驾驭,导致位于设计者下游的使用者无从下手.

以delphi厂商的某些程序员+设计者为例,他们的工作是维护和开发delphi.我在2016年时看见他们还在折腾opengl入门,显然错过了open1.x(固管) -> open2.0(可编程管线)的历史性升级时代,delphi通过商业路线收购dxscene,fmx被提上前台,这是被动行为,这并不是开创型做法.如果设计者在半路上出现自我局限,项目无法达标,使用者就会非常非常被动.

总结:ZNet代表未来整个后台服务器体系,保持开放,保持升级更新.


## 1.4 引入并优化计算机图形学体系

DrawEngine简称DE,定位是轻量+标准化,它需要渲染输出接口.位于前端用户层.
	
图形API标准源自Khronos,软硬厂商也会有自己的规范,这些规范,大都反应在像素排列,像素优化,api优化这些机制上.
	
同时图形api也有许多标准,metal,opengl,gles,vulkan,d3d,这就造成了一种局面:渲染器要兼容各种平台和api,需要大量接口,并且这些接口升级更新非常快,这让渲染引擎的开发和维护变得不容易了.DE在设计定位直接避开了前面的标准接口和平台化,做中间件:渲染api差异大没事,渲染器能在目标平台把至少一种api体系支持到位那就没问题.

FMX的底层是一种渲染器,对于多平台api支持程度,其实做的是可以的,用来设计游戏,VR都是没问题的.DE是把FMX当成输出接口来用,但不会局限于FMX.DE不是渲染器定位.

DrawEngine的应用并不是直接让程序写完流程,因为渲染需要数据来源,例如,视频,图片,各种可视线框,大多时候,这要工具链,后台,内容生产这类体系来支撑.纯代码路线无法驾驭.
	
另一方面,DE有一定计算机图形学的全局视野.它走了自己路线.

在1.4更新中,DrawEngine的渲染调度能力被大幅优化.

**计算机图形学solve组成部分**
### 光栅系统
- Agg分支:以Agg命名开头的体系库,给出了线条平滑性solve
- 投影分支:由光栅字体分支,尺度化,api支持分支共同组成
- CV分支:形态学分支,像素分割分支,共同组成
### 渲染系统
- 文本渲染:彩字,倾斜字,自定义字,脚本化文本
- 图片渲染:没输出接口走光栅流程,有输出接口走渲染器流程
- 线框绘制和填充:以原子操作,点,线,园,扩展一堆高级api
- 命令队列:就是把渲染api调用,和物理输出api绘制分离开,用至少两个线程提速
- 粒子:粒子是个重要分支,做特效,视觉方向使用
- 运动引擎:运动是渲染引擎必须支持子系统,作用是统一规范,减少实现运动化渲染代码工作,运动引擎是在1.4新引入的分支
- 场景支持:如果复杂项目,例如,2d游戏,AI建模系统,场景是渲染引擎的必须支持的标准规范,在DE中场景化渲染以DrawInScene这类api来使用

# 部署与编译

1. **首先部署建模工具链, 开源版工具链体系确定可完成自主建模**
[建模与生产工具链部署](https://zpascal.net/%E9%A6%96%E6%AC%A1%E4%BD%BF%E7%94%A8%E5%BC%80%E6%BA%90%E7%89%88%E5%B7%A5%E5%85%B7%E9%93%BE.pdf)
2. **准备好计算引擎**
[计算引擎部署](https://zpascal.net/%E4%BD%BF%E7%94%A8%E5%BC%80%E5%8E%9F%E7%89%88%E8%AE%A1%E7%AE%97%E5%BC%95%E6%93%8E.pdf)
3. **编译说明**
[编译说明](https://zpascal.net/%E7%BC%96%E8%AF%91ZAI1.4%E5%BC%80%E6%BA%90%E7%89%88%E6%9C%AC%E6%BA%90%E7%A0%81.pdf)

## 部署AI-Demo运行数据

- AI-Demo所需运行数据,将数据解压到"Z-AI1.4\AI-demo\Binary\"目录 [下载](http://zpascal.net/AI-Demo-Data.rar)
- 先解压运行数据,再用计算引擎覆盖,颠倒顺序可能导致结果无法预料

# 建模入门与指引

请阅读: [1.34老版本文档](https://zpascal.net/OLD_Index.html)

# gpu支持性

请阅读: [详情](https://zpascal.net/GPU_Support.htm)

# delphi编译结果(编译测试版本XE10.4.2与XE11.3)

| 架构   | AI-Demo | tools | Net-tools | Net-Advance-Demo | Net-C4-Demo | Net-demo |
| ------- | :------: | :------: | :------: | :------: | :------: | :------: |
| x86  | Passed | Passed | Passed | Passed | Passed | Passed |
| x64  | Passed | Passed | Passed | Passed | Passed | Passed |
| MKL64  | Passed | Passed | Passed | Passed | Passed | Passed |
| CUDA10  | Passed | Passed | Passed | Passed | Passed | Passed |
| CUDA11  | Passed | Passed | Passed | Passed | Passed | Passed |
| CUDA12  | Passed | Passed | Passed | Passed | Passed | Passed |

# fpc编译结果

**fpc编译器测试通过source目录中的全部库,source目录子目录为平台关联性,fpc不支持**


# 有问题可到zAI机器学习群提出

- qq群号811381795
- 也可以直接加作者qq600585


完

2023-7-26
