FROM ruby:2.1-onbuild
ENTRYPOINT ["bin/entrypoint.sh"]
CMD ["--help"]
