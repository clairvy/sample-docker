FROM centos:centos6

# ssh, sudo
RUN yum install -y sudo openssh-server
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
RUN ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N ''

# user
RUN useradd -d /home/kitchen -m -s /bin/bash kitchen
RUN echo kitchen:kitchen | chpasswd
RUN echo 'kitchen ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN mkdir /home/kitchen/.ssh
RUN ssh-keygen -f /home/kitchen/.ssh/id_rsa -t rsa -b 2048 -N ''
RUN cp /home/kitchen/.ssh/id_rsa.pub /home/kitchen/.ssh/authorized_keys
RUN chmod 0600 /home/kitchen/.ssh/authorized_keys
RUN chown -Rh kitchen /home/kitchen

# supervisord
RUN yum install -y python-setuptools
RUN easy_install supervisor
ADD files/etc/supervisord.conf /etc/supervisord.conf

# nginx
RUN rpm -ivh http://nginx.org/packages/centos/6/noarch/RPMS/nginx-release-centos-6-0.el6.ngx.noarch.rpm
RUN yum -y install nginx

CMD ["/usr/bin/supervisord"]
