#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <string.h>

#define BUFFER_BYTES 100
#define OPTION_BUFFER_BYTES 5

int interactive_requests(int sockfd);
int get_time(int sockfd);
int get_weather(int sockfd);
int request(int sockfd, char *message);
void close_conn(int sockfd);
int runclient(char *server_ip, int server_port);

/**
 * interactive_requests interacts with 
 * the user and performs given commands
 */
int interactive_requests(int sockfd) {

    char option_buffer[OPTION_BUFFER_BYTES];
    int stop = 0;

    while (stop == 0) {
        // print options
        printf("please choose an option by"
            " entering the corresponding number\n"
            "     1 get time\n"
            "     2 get weather\n"
            "     3 exit\n"
            "     4 repeat options\n");

        // get option from user
        memset(option_buffer, 0, OPTION_BUFFER_BYTES);
        fgets(option_buffer, OPTION_BUFFER_BYTES, stdin);

        // parse and execute option
        if (option_buffer[0] == '1') {
            stop = get_time(sockfd);
        } else if (option_buffer[0] == '2') {
            stop = get_weather(sockfd);
        } else if (option_buffer[0] == '3') {
            stop = 1;
        } else if (option_buffer[0] == '4') {
            // do nothing, options will repeat
        } else {
            printf("we did not understand your request\n");
        }
    }

    return 0;
}

int get_time(int sockfd) {
    char *msg = "GET time";
    return request(sockfd, msg);
}

int get_weather(int sockfd) {
    char *msg = "GET weather";
    return request(sockfd, msg);
}

int request(int sockfd, char *msg) {

    char send_buffer[BUFFER_BYTES];
    char recv_buffer[BUFFER_BYTES];
    int msg_size, send_result;
    
    // send request
    strncpy(send_buffer, msg, BUFFER_BYTES);
    printf("sending: %s\n", send_buffer);
    send_result = write(
        sockfd, 
        send_buffer, 
        strlen(send_buffer)
    );
    if (send_result < 0) {
        perror("error sending");
        return 1;
    }

    // receive response
    memset(recv_buffer, 0, BUFFER_BYTES);
     msg_size = read(
        sockfd, 
        recv_buffer, 
        BUFFER_BYTES
    );

    // display response
    printf("response: %s\n", recv_buffer);

    return 0;
}

void close_conn(int sockfd) {
	close(sockfd);
}

int runclient(char *server_ip, int server_port) {

    int sockfd;
    int connect_result;
    struct sockaddr_in server_addr;

    // create client socket
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) {
        perror("error opening socket");
        return 1;
    }

    // create server address struct
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(server_port);
    inet_aton(server_ip, &server_addr.sin_addr);

    // connect to server
    connect_result = connect(
        sockfd, 
        (struct sockaddr *) &server_addr, 
        sizeof(server_addr)
    );
    if (connect_result < 0) {
        perror("error connecting to server");
        return 1;
    }
    printf(
        "connected to server at %s:%d\n",
        server_ip,
        server_port
    );

    // send requests interactively
    interactive_requests(sockfd);

    close_conn(sockfd);
    return 0;
}

int main(int argc, char *argv[]) {

    // extract port and server_port
    // from cmd line
    if (argc < 3) {
        perror("missing arguments");
        return 1;
    }
    char *server_ip = argv[1];
    int server_port = atoi(argv[2]);

    return runclient(server_ip, server_port);
}




















