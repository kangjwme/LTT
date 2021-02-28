# LTT(Linux TesT shell)
一個讓Linux系統秘密慢慢揭露的小腳本＼(＠＾０＾＠)/

功能列表：
        <li>✔顯示CPU資訊、時脈、L2快取大小</li>
	<li>✔顯示硬碟、記憶體、SWAP大小</li>
	<li>✔顯示開機時間、平均附載(Average Load)</li>
	<li>✔顯示作業系統、為源價購</li>
	<li>✔顯示內核Kernal版本</li>
	<li>✔顯示虛擬化架構(KVM/OpenVZ等等)</li>
	<li>✔顯示主機IP所屬數據中心/位置</li>
	<li>✔dd測速</li>
	<li>✔speedtest測速(最近節點+台灣北中南電信)</li>
        
        
使用指令如下：

```
wget -qO-  | bash
```
使用範例如下(感謝UpCloud贊助主機借我~~操~~測試)：
```
----------------------------------------------------------------------
        處理器型號      ：      AMD EPYC 7542 32-Core Processor
        處理器核心      ：      1
        處理器時脈      ：      2894.556 MHz
        處理器快取      ：      512 KB
        總硬碟大小      ：      25.0 GB (1.4 GB 已使用)
        記憶體大小      ：      979 MB (156 MB 已使用)
        SWAP總量        ：      0 MB (0 MB 已使用)
        開機時間        ：      0 天, 0 小時 4 分鐘
        平均附載        ：      0.02, 0.08, 0.04
        作業系統        ：      CentOS Linux release 8.2.2004 (Core) 
        位元架構        ：      x86_64 (64 位元)
        內核版本        ：      4.18.0-193.6.3.el8_2.x86_64
        虛擬技術        ：      KVM
        數據中心登記    ：      AS202053 UpCloud Ltd
        主機詳細位置    ：      Singapore / SG
        主機所在省州    ：      Singapore
----------------------------------------------------------------------
 讀寫速度(第一次測試)    : 422 MB/s
 讀寫速度(第二次測試)    : 420 MB/s
 讀寫速度(第三次測試)    : 433 MB/s
----------------------------------------------------------------------
 台北 中華電信97.37 Mbps          95.77 Mbps              49.31 ms                
 新北 台灣之星99.18 Mbps          95.95 Mbps              54.56 ms                
 台中 中華電信98.50 Mbps          96.56 Mbps              51.03 ms                
 高雄 中華電信98.80 Mbps          96.24 Mbps              53.33 ms  
```
##怎麼添加Speedtest測速節點
打開ltt.sh，搜尋`#這邊可以自行新增speedtest節點`，依照格式複製貼上即可

至於server ID怎麼找，有兩種方式
1. https://www.speedtest.net/speedtest-servers.php 可以找到你附近的speedtest節點
2. https://williamyaps.github.io/wlmjavascript/servercli.html 可以利用Ctrl+F搜尋，但有些好像都不能用(?
