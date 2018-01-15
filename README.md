### INSTALLATION NOTES

1. Python websocker server:

    + [Flask sockets](https://github.com/kennethreitz/flask-sockets)

    + Money patching to: `sklearn.manifold.t_sne._gradient_descent` function.


2. Redis server:
    + Install, run service:

        ```
        sudo apt-get install redis-server
        sudo systemctl restart redis-server.service
        sudo systemctl enable redis-server.service # enable on system boot
        ```

    + Python lib: [Redis-py](https://github.com/andymccurdy/redis-py)

        `pip install redis`

    + Monitor:

        * [MONITOR](https://redis.io/commands/monitor) command.
        * [Redis-stat](https://github.com/junegunn/redis-stat)
            - Run: `java -jar redis-stat-0.4.14.jar --server`
            - Host: `http://localhost:63790/`