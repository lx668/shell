说明:脚本完成代码部署回滚

1.日志记录
2.上锁机制
3.支持批量代码部署
4.支持版本回退，默认回退到上一版本，也可以回退到任何一版本
5.支持多项目多目录发布

使用方法：
sh deploy_all.sh deploy chaos bi-test  代码部署
sh deploy_all.sh rollback chaos bi-test 代码回滚上一个版本
sh deploy_all.sh rollback chaos bi-test-2016-09-02-12-03-56
