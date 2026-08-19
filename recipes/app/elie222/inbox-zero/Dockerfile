# syntax=docker/dockerfile:1
#
# The pinned upstream image, extended with two things and nothing else: the build
# output moved aside as a template, and an entrypoint that restores it into the
# writable mount. See droplive-entrypoint.sh for why that mount has to be writable.
FROM ghcr.io/elie222/inbox-zero@sha256:b543689db188d252b7032327129f9f019c0d3257a4febff7a98005cd9318ec14

# `.next` becomes a mount point, so its contents move somewhere the mount cannot
# hide. The empty directory left behind is what DropLive's volume covers.
RUN mv /app/apps/web/.next /opt/droplive-next \
 && mkdir -p /app/apps/web/.next

COPY --chmod=0755 droplive-entrypoint.sh /usr/local/bin/droplive-entrypoint.sh

# The image's own command is unchanged and still runs; this only precedes it.
ENTRYPOINT ["/usr/local/bin/droplive-entrypoint.sh"]
CMD ["/app/docker/scripts/start.sh"]
