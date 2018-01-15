Python websocker server:
https://github.com/kennethreitz/flask-sockets

Money patching to: sklearn.manifold.t_sne._gradient_descent function.


Redis server:
    + Install, run service:
        sudo apt-get install redis-server
        sudo systemctl restart redis-server.service
        sudo systemctl enable redis-server.service # enable on system boot

    + Python lib: https://github.com/andymccurdy/redis-py
        pip install redis

    + Monitor:
        * MONITOR command
        * Redis-stat: https://github.com/junegunn/redis-stat
            Run: java -jar redis-stat-0.4.14.jar --server
            Host: http://localhost:63790/