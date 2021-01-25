FROM openjdk:8-jre-slim

RUN apt-get update \
  && apt-get install -y \
    file \
    make \
    sudo\
    unzip

ARG UID=1000
ARG GID=1000
RUN groupadd grader -g "${GID}" \
  && useradd -rm -d /grader -s /bin/bash -g grader -u "${UID}" grader  
WORKDIR /grader

COPY --chown=grader:grader Makefile .
COPY --chown=grader:grader spec ./spec
COPY --chown=grader:grader docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x ./spec/nand2tetris/tools/*.sh

# fix 00.test using files from demo dir
RUN cp -r ./spec/nand2tetris/projects/demo/* ./spec/nand2tetris/projects/00/.
# works if /results is not mounted as volume
RUN mkdir -p /results \
  && chown grader: /results

USER grader

# ENVs which you can choose different defaults on build time
ARG SUBMISSION="/submission"
ENV SUBMISSION="${SUBMISSION}"
ARG RESULTS_DIR="/results"
ENV RESULTS_DIR="${RESULTS_DIR}"
ARG QUIET="no"
ENV QUIET="${QUIET}"
ARG STRIP_SH_ARGS="no"
ENV STRIP_SH_ARGS="${STRIP_SH_ARGS}"

ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "00.test" ]
