USE [DRAS_IRASv6_DEMO_QA]
GO

ALTER TABLE [dbo].[PipeSegment]  WITH CHECK ADD  CONSTRAINT [FK_PipeSeamDomainId] FOREIGN KEY([PipeSeamDomainId])
REFERENCES [dbo].[PipeSeam] ([Id])
GO

ALTER TABLE [dbo].[PipeSegment] CHECK CONSTRAINT [FK_PipeSeamDomainId]
GO


