# skynet-rankserver

* 用skynet做排行服务 
* 目标：
  - 作一个全服排行服务
  - 用skiplist支持实时排行
  - 支持http请求+json数据
  - 存储用redis
* 缺陷： 
  - 排行只根据分数从大到小(当分数相同时 则可能出现不稳定性)
  - 数据量大时 可以考虑用其他排序方法(比如桶排序)
  - 暂不考虑过频请求以及攻击
  
* 接口定义：
 1. 当玩家到达最大分数(不是最大分数不要提交)
  - 请求数据示例： {"cmd":"CommitData", data:{"uid":1001, "name":"andy", "headIcon":"", "score":99} 
    - 参数说明：
    ```
      cmd:请求命令类型
      data:请求参数(json数据）
        uid: 玩家id
        name: 玩家名
        headIcon: 玩家头像url
        score: 玩家分数    
      ```
  - 返回数据示例: {"ret":0}
    - 参数说明：
    ```
      ret: 返回值 0 表示正常 其他值则不正常 待定
    ```
 2. 请求排行榜
 - 请求数据示例： {"cmd":"GetRankList", data:{"uid":1001, "startindex":1, "endindex":100} 
    - 参数说明：
    ```
      cmd:请求命令类型
      data:请求参数(json数据）
        uid: 玩家id
        startindex:排行榜开始下标
        endindex:排行榜结束下标（两者之差不能大于100）
      ```
  - 返回数据示例: {"ret":0, list:[{"rank":1,"uid":1001,"score":99},{"rank":2, "uid":1002,"score":98}]}
    - 参数说明：
    ```
      ret: 返回值 0 表示正常 其他值则不正常 待定
      list: 排行榜数据
        rank:排名
        uid:玩家id
        name:玩家名
        headIcon:玩家头像
        score:玩家分数 
    ```
  3. 重置排行榜(清除所有排行数据 此接口一般用户不能请求 需要权限）:
  - 请求数据示例：{"cmd":"ResetRank"}
    - 参数说明：
    ```
      cmd:请求命令类型
    ```
    - 返回数据示例: {"ret":0}
    - 参数说明：
    ```
      ret: 返回值 0 表示正常 其他值则不正常 待定
    ```
    
    
