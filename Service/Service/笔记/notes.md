
#include <sys/socket.h>

//sock 套接字文件描述符
//连接请求等待队列的长度，若为5，表示最多使5个连接请求进入队列
int listen(int sock, int backlog);
